import json
import os
import urllib.request
import boto3 # type: ignore

ENDPOINT_URL = os.environ["ENDPOINT_URL"]
DLQ_URL = os.environ["DLQ_URL"]

sqs = boto3.client("sqs")


def handler(event, context):
    """
    Generic event proxy. Forwards the incoming event as JSON
    to a configured HTTP endpoint via POST.
    On failure, sends the event to an SQS dead-letter queue.
    Always returns the original event so callers (e.g. Cognito triggers) succeed.
    """
    payload = json.dumps(event).encode("utf-8")

    try:
        req = urllib.request.Request(
            ENDPOINT_URL,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"Proxy OK: {resp.status}")
            
    except Exception as e:
        print(f"Proxy failed: {e}")
        try:
            sqs.send_message(
                QueueUrl=DLQ_URL,
                MessageBody=json.dumps({
                    "source": event.get("triggerSource", "unknown"),
                    "error": str(e),
                    "event": event,
                }),
            )
            print("Event sent to DLQ")
        except Exception as sqs_err:
            print(f"DLQ send also failed: {sqs_err}")
            
    return event
