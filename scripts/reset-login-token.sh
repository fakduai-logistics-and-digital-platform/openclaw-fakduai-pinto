#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
ENV_EXAMPLE="$ROOT_DIR/.env.example"

if [ ! -f "$ENV_FILE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "Created .env from .env.example"
fi

if command -v openssl >/dev/null 2>&1; then
  token="$(openssl rand -hex 32)"
else
  token="openclaw-$(date '+%Y%m%d%H%M%S')"
fi

tmp="$ENV_FILE.tmp"
if grep -q '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE"; then
  awk -v token="$token" '
    index($0, "OPENCLAW_GATEWAY_TOKEN=") == 1 {
      print "OPENCLAW_GATEWAY_TOKEN=" token
      next
    }
    { print }
  ' "$ENV_FILE" > "$tmp"
else
  cp "$ENV_FILE" "$tmp"
  printf '\nOPENCLAW_GATEWAY_TOKEN=%s\n' "$token" >> "$tmp"
fi
mv "$tmp" "$ENV_FILE"

echo "New OpenClaw Web UI login token:"
echo "$token"
echo
echo "Restart the gateway:"
echo "  docker compose restart openclaw-gateway"
echo
echo "Then reload the browser and paste the token above."
