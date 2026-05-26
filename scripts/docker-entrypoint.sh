#!/usr/bin/env sh
set -eu

PLUGIN_ID="${PINTO_PLUGIN_ID:-pinto-app-openclaw}"
PLUGIN_PACK="${PINTO_PLUGIN_PACK:-/opt/openclaw-plugins/pinto-app-openclaw.tgz}"
OPENCLAW_CLI="${OPENCLAW_CLI:-/app/dist/index.js}"

is_enabled() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

if is_enabled "${PINTO_PLUGIN_AUTO_INSTALL:-1}"; then
  if node "$OPENCLAW_CLI" plugins inspect "$PLUGIN_ID" >/dev/null 2>&1; then
    echo "Pinto plugin already installed: $PLUGIN_ID"
  else
    echo "Installing Pinto plugin from image: $PLUGIN_PACK"
    node "$OPENCLAW_CLI" plugins install "npm-pack:$PLUGIN_PACK"
  fi

  node /usr/local/bin/bootstrap-pinto-channel.mjs

  if is_enabled "${PINTO_PLUGIN_AUTO_ENABLE:-1}"; then
    node "$OPENCLAW_CLI" plugins enable "$PLUGIN_ID" >/dev/null 2>&1 || true
  fi
fi

exec "$@"
