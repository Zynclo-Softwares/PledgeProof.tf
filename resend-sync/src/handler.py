"""
Resend Contact Sync Lambda handler — syncs Cognito emails to Resend audience.

Triggered by EventBridge Scheduler 3× daily.
Environment variables:
  RESEND_API_KEY       — Resend API key
  COGNITO_USER_POOL_ID — Cognito User Pool ID (default: ca-central-1_NFOMStQGX)
"""

import json
import os
from urllib.request import Request, urlopen
from urllib.error import HTTPError

import boto3

RESEND_BASE_URL = "https://api.resend.com"
AUDIENCE_NAME = "PledgeProof Users"


def resend_request(method: str, path: str, api_key: str, body: dict | None = None) -> dict:
    url = f"{RESEND_BASE_URL}{path}"
    data = json.dumps(body).encode() if body else None
    req = Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "PledgeProof-ResendSync/1.0")
    with urlopen(req) as resp:
        return json.loads(resp.read().decode())


def fetch_cognito_emails(pool_id: str) -> set[str]:
    region = pool_id.split("_")[0]
    client = boto3.client("cognito-idp", region_name=region)
    emails: set[str] = set()
    pagination_token = None

    while True:
        kwargs = {"UserPoolId": pool_id, "AttributesToGet": ["email"], "Limit": 60}
        if pagination_token:
            kwargs["PaginationToken"] = pagination_token

        response = client.list_users(**kwargs)
        for user in response.get("Users", []):
            for attr in user.get("Attributes", []):
                if attr["Name"] == "email" and attr["Value"]:
                    emails.add(attr["Value"].lower().strip())

        pagination_token = response.get("PaginationToken")
        if not pagination_token:
            break

    return emails


def get_or_create_audience(api_key: str) -> str:
    audiences = resend_request("GET", "/audiences", api_key)
    for aud in audiences.get("data", []):
        if aud["name"] == AUDIENCE_NAME:
            return aud["id"]

    result = resend_request("POST", "/audiences", api_key, {"name": AUDIENCE_NAME})
    return result["id"]


def fetch_existing_contacts(api_key: str, audience_id: str) -> set[str]:
    contacts = resend_request("GET", f"/audiences/{audience_id}/contacts", api_key)
    return {c["email"].lower().strip() for c in contacts.get("data", []) if c.get("email")}


def handler(event, _context):
    api_key = os.environ["RESEND_API_KEY"]
    pool_id = os.environ.get("COGNITO_USER_POOL_ID", "ca-central-1_NFOMStQGX")

    trigger = event.get("trigger", "manual")
    print(f"Resend sync triggered: {trigger}")

    # 1. Fetch Cognito emails
    cognito_emails = fetch_cognito_emails(pool_id)
    print(f"Cognito: {len(cognito_emails)} unique emails")

    if not cognito_emails:
        return {"status": "no_users", "added": 0}

    # 2. Get or create audience
    audience_id = get_or_create_audience(api_key)
    print(f"Audience: {audience_id}")

    # 3. Get existing contacts
    existing = fetch_existing_contacts(api_key, audience_id)
    new_emails = cognito_emails - existing
    print(f"Existing: {len(existing)}, New: {len(new_emails)}")

    if not new_emails:
        return {"status": "synced", "added": 0, "total": len(cognito_emails)}

    # 4. Add new contacts
    added = 0
    for email in sorted(new_emails):
        try:
            resend_request("POST", f"/audiences/{audience_id}/contacts", api_key, {
                "audience_id": audience_id,
                "email": email,
            })
            added += 1
        except (HTTPError, Exception) as e:
            print(f"Failed to add {email}: {e}")

    print(f"Done: added {added}/{len(new_emails)}")
    return {"status": "synced", "added": added, "total": len(cognito_emails)}
