#!/usr/bin/env python3
import os
import sys
import time
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
KEY_PATH = Path(os.environ.get(
    "ASC_KEY_PATH",
    str(Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{KEY_ID}.p8"),
))

BUNDLE_IDENTIFIER = os.environ.get("BUNDLE_IDENTIFIER", "com.tokyonasu.boatracepredictor")
BUNDLE_NAME = os.environ.get("BUNDLE_NAME", "舟読み")
BASE_URL = "https://api.appstoreconnect.apple.com/v1"


def make_token():
    key = KEY_PATH.read_text()
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def request(method, path, **kwargs):
    headers = {
        "Authorization": f"Bearer {make_token()}",
        "Content-Type": "application/json",
    }
    return requests.request(method, f"{BASE_URL}{path}", headers=headers, timeout=60, **kwargs)


def api_json(method, path, **kwargs):
    response = request(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    return response, body


def main():
    if not KEY_PATH.exists():
        print(f"API key not found: {KEY_PATH}")
        print("Put the .p8 key there, or set ASC_KEY_PATH.")
        return 1

    response, body = api_json("GET", f"/bundleIds?filter[identifier]={BUNDLE_IDENTIFIER}&limit=1")
    if response.status_code != 200:
        print(f"Could not check existing Bundle IDs: {response.status_code}")
        print(response.text[:1000])
        return 1

    items = body.get("data", [])
    if items:
        item = items[0]
        print("Bundle ID already exists.")
        print(f"Name: {item['attributes'].get('name')}")
        print(f"Identifier: {item['attributes'].get('identifier')}")
        print(f"Apple resource ID: {item['id']}")
        return 0

    payload = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "name": BUNDLE_NAME,
                "identifier": BUNDLE_IDENTIFIER,
                "platform": "IOS",
            },
        }
    }
    response, body = api_json("POST", "/bundleIds", json=payload)
    if response.status_code not in (200, 201):
        print(f"Bundle ID registration failed: {response.status_code}")
        print(response.text[:1000])
        return 1

    item = body["data"]
    print("Bundle ID registered.")
    print(f"Name: {item['attributes'].get('name')}")
    print(f"Identifier: {item['attributes'].get('identifier')}")
    print(f"Apple resource ID: {item['id']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
