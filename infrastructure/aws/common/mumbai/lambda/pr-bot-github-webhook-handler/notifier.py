import json
import os
import requests
import boto3
from security import verify_github_signature

# Secrets from Environment or AWS Secrets Manager
SLACK_WEBHOOK_URL = os.environ['SLACK_WEBHOOK_URL']
GITHUB_WEBHOOK_SECRET = os.environ['GITHUB_WEBHOOK_SECRET']

def lambda_handler(event, context):
    try:
        # 1. Get Headers and Raw Body
        headers = event.get('headers', {})
        raw_body = event.get('body', '')

        # 2. SECURITY: Verify GitHub Signature
        verify_github_signature(headers, raw_body, GITHUB_WEBHOOK_SECRET)

        # 3. Parse Event
        payload = json.loads(raw_body)
        action = payload.get('action')

        # Only care about new PRs
        if action == 'opened':
            pr = payload['pull_request']
            repo = payload['repository']

            # 4. Construct Slack Message with Interactive Button
            slack_payload = {
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"*New PR:* <{pr['html_url']}|{pr['title']}>\n*Repo:* {repo['full_name']}\n*Author:* {pr['user']['login']}"
                        }
                    },
                    {
                        "type": "actions",
                        "elements": [
                            {
                                "type": "button",
                                "text": {
                                    "type": "plain_text",
                                    "text": "Approve PR :white_check_mark:"
                                },
                                "style": "primary",
                                "value": json.dumps({
                                    "owner": repo['owner']['login'],
                                    "repo": repo['name'],
                                    "pr_number": pr['number']
                                }),
                                "action_id": "approve_pr_button"
                            }
                        ]
                    }
                ]
            }

            requests.post(SLACK_WEBHOOK_URL, json=slack_payload)

        return {"statusCode": 200, "body": "Event processed"}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"statusCode": 401, "body": "Unauthorized or Error"}
