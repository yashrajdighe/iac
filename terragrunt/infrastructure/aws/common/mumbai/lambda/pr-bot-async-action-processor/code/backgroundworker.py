import json
import os
import time
import base64
import requests
import jwt
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

GITHUB_APP_ID = os.environ['GITHUB_APP_ID']
encoded_key = os.environ['GITHUB_PRIVATE_KEY']
GITHUB_PRIVATE_KEY = base64.b64decode(encoded_key)

def get_github_installation_token(owner, repo):
    try:
        payload = {'iat': int(time.time()), 'exp': int(time.time()) + 600, 'iss': GITHUB_APP_ID}
        encoded_jwt = jwt.encode(payload, GITHUB_PRIVATE_KEY, algorithm='RS256')
        headers = {"Authorization": f"Bearer {encoded_jwt}", "Accept": "application/vnd.github.v3+json"}

        url = f"https://api.github.com/repos/{owner}/{repo}/installation"
        installation_id = requests.get(url, headers=headers).json()['id']

        token_url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
        return requests.post(token_url, headers=headers).json()['token']
    except Exception as e:
        logger.error(f"Token Error: {str(e)}")
        raise e

def map_slack_user_to_github(user_id):
    # Update this with your real mapping
    user_map = {"U06PXG6KUNN": "yashraj-dighe"}
    return user_map.get(user_id)

def lambda_handler(event, context):
    logger.info("--- Worker Started ---")

    response_url = event['response_url']
    user_id = event['user_id']
    owner = event['owner']
    repo = event['repo']
    pr_number = event['pr_number']
    original_text = event.get('original_text', '*PR Update*')

    try:
        # 1. Auth Check
        github_user = map_slack_user_to_github(user_id)
        if not github_user:
            requests.post(response_url, json={
                "replace_original": "false",
                "text": f"❌ Error: Slack User <@{user_id}> is not linked to a GitHub account."
            })
            return

        # 2. GitHub Actions
        token = get_github_installation_token(owner, repo)
        api_headers = {"Authorization": f"token {token}", "Accept": "application/vnd.github.v3+json"}

        # Approve
        logger.info("Approving PR...")
        requests.post(
            f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/reviews",
            json={"event": "APPROVE", "body": "Approved via Slack"},
            headers=api_headers
        )

        # Merge
        logger.info("Merging PR...")
        merge_resp = requests.put(
            f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/merge",
            json={"commit_title": f"Merged PR #{pr_number}", "merge_method": "merge"},
            headers=api_headers
        )

        # 3. Final Slack Update
        if merge_resp.status_code in [200, 201]:
            # Success
            new_blocks = [
                {"type": "section", "text": {"type": "mrkdwn", "text": original_text}},
                {"type": "context", "elements": [{"type": "mrkdwn", "text": f"🚀 *Approved & Merged* by <@{user_id}>"}]}
            ]
            payload = {"replace_original": "true", "blocks": new_blocks}
        else:
            # Failure
            payload = {
                "replace_original": "false",
                "text": f"✅ Approved, but ❌ **Merge Failed**: {merge_resp.json().get('message')}"
            }

        logger.info(f"Updating Slack UI at: {response_url}")
        slack_resp = requests.post(response_url, json=payload)

        # LOGGING THE SLACK RESPONSE IS CRITICAL FOR DEBUGGING
        logger.info(f"Slack Update Response: {slack_resp.status_code} - {slack_resp.text}")

    except Exception as e:
        logger.exception("Worker Failed")
        requests.post(response_url, json={
            "replace_original": "false",
            "text": f"⚠️ System Error: {str(e)}"
        })
