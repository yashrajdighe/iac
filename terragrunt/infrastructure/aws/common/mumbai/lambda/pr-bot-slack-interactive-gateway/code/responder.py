import json
import os
import boto3
import base64
import logging
from urllib.parse import parse_qs
from security import verify_slack_signature

# --- GLOBAL INIT (Crucial for Speed) ---
logger = logging.getLogger()
logger.setLevel(logging.INFO)
lambda_client = boto3.client('lambda')

SLACK_SIGNING_SECRET = os.environ['SLACK_SIGNING_SECRET']
WORKER_LAMBDA_NAME = os.environ['WORKER_LAMBDA_NAME']

def lambda_handler(event, context):
    try:
        # 1. Verify & Parse (Fastest possible path)
        raw_body = event.get('body', '')
        if event.get('isBase64Encoded'):
             raw_body = base64.b64decode(raw_body).decode('utf-8')

        verify_slack_signature(event.get('headers', {}), raw_body, SLACK_SIGNING_SECRET)

        parsed_body = parse_qs(raw_body)
        payload_json = json.loads(parsed_body['payload'][0])
        action_value = json.loads(payload_json['actions'][0]['value'])

        # 2. Extract Context (Safely)
        original_blocks = payload_json.get('message', {}).get('blocks', [])
        original_text = "PR Update" # Default
        for block in original_blocks:
            if block['type'] == 'section' and 'text' in block:
                original_text = block['text']['text']
                break

        # 3. Fire Worker (Async)
        worker_payload = {
            "response_url": payload_json['response_url'],
            "user_id": payload_json['user']['id'],
            "owner": action_value['owner'],
            "repo": action_value['repo'],
            "pr_number": action_value['pr_number'],
            "original_text": original_text
        }

        lambda_client.invoke(
            FunctionName=WORKER_LAMBDA_NAME,
            InvocationType='Event',
            Payload=json.dumps(worker_payload)
        )

        # 4. Immediate Response to Slack
        # We explicitly set response_type to ensure Slack knows we are replacing the message.
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "response_type": "in_channel",
                "replace_original": "true",
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"{original_text}\n\n:hourglass_flowing_sand: *Processing approval & merge...*"
                        }
                    }
                ]
            })
        }

    except Exception as e:
        logger.error(f"Receiver Error: {str(e)}")
        # Even on error, return 200 to Slack with an error message to stop the spinner
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"text": "⚠️ Request failed. Please try again."})
        }
