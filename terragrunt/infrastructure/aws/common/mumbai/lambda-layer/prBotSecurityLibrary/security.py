import hmac
import hashlib
import time

def verify_github_signature(headers, raw_body, secret_token):
    """
    Verifies that the request came from GitHub.
    Headers must include 'X-Hub-Signature-256'.
    """
    signature_header = headers.get('X-Hub-Signature-256') or headers.get('x-hub-signature-256')

    if not signature_header:
        raise Exception("Missing X-Hub-Signature-256 header")

    # Create the HMAC SHA256 signature
    hash_object = hmac.new(
        secret_token.encode('utf-8'),
        msg=raw_body.encode('utf-8'),
        digestmod=hashlib.sha256
    )
    expected_signature = "sha256=" + hash_object.hexdigest()

    if not hmac.compare_digest(expected_signature, signature_header):
        raise Exception("Invalid GitHub Signature")
    return True

def verify_slack_signature(headers, raw_body, signing_secret):
    """
    Verifies that the request came from Slack.
    Headers must include 'X-Slack-Signature' and 'X-Slack-Request-Timestamp'.
    """
    timestamp = headers.get('X-Slack-Request-Timestamp') or headers.get('x-slack-request-timestamp')
    signature = headers.get('X-Slack-Signature') or headers.get('x-slack-signature')

    if not timestamp or not signature:
        raise Exception("Missing Slack verification headers")

    # 1. Replay Attack Prevention: Check if timestamp is too old (e.g., > 5 mins)
    if abs(time.time() - int(timestamp)) > 60 * 5:
        raise Exception("Slack request timestamp expired")

    # 2. Verify Signature
    sig_basestring = f"v0:{timestamp}:{raw_body}"
    my_signature = 'v0=' + hmac.new(
        signing_secret.encode('utf-8'),
        sig_basestring.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(my_signature, signature):
        raise Exception("Invalid Slack Signature")
    return True
