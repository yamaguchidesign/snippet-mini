#!/bin/bash
# App Store Connect に macOS アプリを新規登録する（API キー必要）
set -euo pipefail

BUNDLE_ID="com.yamaguchidesign.snippet-mini"
APP_NAME="Snippet Mini"
SKU="snippet-mini"
KEY_ID="${APP_STORE_CONNECT_API_KEY_ID:?Set APP_STORE_CONNECT_API_KEY_ID}"
ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:?Set APP_STORE_CONNECT_ISSUER_ID}"
KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:?Set APP_STORE_CONNECT_API_KEY_PATH}"

python3 <<PY
import jwt, time, json, urllib.request, os, sys

key_id = os.environ["APP_STORE_CONNECT_API_KEY_ID"]
issuer = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
key_path = os.environ["APP_STORE_CONNECT_API_KEY_PATH"]

with open(key_path, "r") as f:
    private_key = f.read()

token = jwt.encode(
    {"iss": issuer, "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
    private_key,
    algorithm="ES256",
    headers={"kid": key_id, "typ": "JWT"},
)

payload = {
    "data": {
        "type": "apps",
        "attributes": {
            "name": "$APP_NAME",
            "bundleId": "$BUNDLE_ID",
            "sku": "$SKU",
            "primaryLocale": "ja",
        },
    }
}

req = urllib.request.Request(
    "https://api.appstoreconnect.apple.com/v1/apps",
    data=json.dumps(payload).encode(),
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    },
    method="POST",
)
try:
    with urllib.request.urlopen(req) as resp:
        print(resp.read().decode())
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(body, file=sys.stderr)
    if "already exists" in body.lower() or e.code == 409:
        print("App record may already exist.")
        sys.exit(0)
    raise
PY

echo "App Store Connect app created (or already exists)."
