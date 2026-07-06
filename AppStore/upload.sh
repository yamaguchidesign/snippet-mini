#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/build/export/SnippetMini.pkg"

if [[ ! -f "$PKG" ]]; then
  echo "Package not found. Run archive/export first."
  exit 1
fi

echo "Uploading SnippetMini.pkg to App Store Connect..."
echo ""
echo "方法 A: API キー（推奨）"
echo "  export APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX"
echo "  export APP_STORE_CONNECT_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
echo "  export APP_STORE_CONNECT_API_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8"
echo ""
echo "  xcrun altool --upload-app -f \"$PKG\" -t macos \\"
echo "    --apiKey \"\$APP_STORE_CONNECT_API_KEY_ID\" \\"
echo "    --apiIssuer \"\$APP_STORE_CONNECT_ISSUER_ID\""
echo ""
echo "方法 B: Xcode Transporter"
echo "  open -a Transporter \"$PKG\""
echo ""
echo "方法 C: Apple ID + アプリ専用パスワード"
echo "  xcrun altool --upload-app -f \"$PKG\" -t macos -u YOUR_APPLE_ID --password @keychain:AC_PASSWORD"
echo ""

if [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" && -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
  xcrun altool --upload-app -f "$PKG" -t macos \
    --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
else
  echo "API キー未設定のため、Transporter を開きます。"
  open -a Transporter "$PKG" 2>/dev/null || open "$PKG"
fi
