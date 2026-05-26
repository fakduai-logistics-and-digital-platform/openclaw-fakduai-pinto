#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo ".env not found. Run: cp .env.example .env" >&2
  exit 1
fi

token="$(grep '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" | tail -n 1 | sed 's/^OPENCLAW_GATEWAY_TOKEN=//')"

if [ -z "$token" ]; then
  echo "OPENCLAW_GATEWAY_TOKEN is empty in .env" >&2
  exit 1
fi

echo "$token"
