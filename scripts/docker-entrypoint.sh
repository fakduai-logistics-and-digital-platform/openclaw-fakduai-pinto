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

# Version baked into the image pack (package/package.json inside the .tgz).
pack_version() {
  tar -xzOf "$PLUGIN_PACK" package/package.json 2>/dev/null | node -e '
    let s = "";
    process.stdin.on("data", (d) => (s += d)).on("end", () => {
      try { process.stdout.write(String(JSON.parse(s).version || "")); }
      catch { process.stdout.write(""); }
    });
  '
}

# Version currently installed in the mounted config volume.
installed_version() {
  node "$OPENCLAW_CLI" plugins list --json 2>/dev/null \
    | PLUGIN_ID="$PLUGIN_ID" node -e '
      let s = "";
      process.stdin.on("data", (d) => (s += d)).on("end", () => {
        try {
          const parsed = JSON.parse(s);
          const list = Array.isArray(parsed)
            ? parsed
            : parsed.plugins || parsed.items || [];
          const found = list.find((p) => p && p.id === process.env.PLUGIN_ID);
          process.stdout.write(found && found.version ? String(found.version) : "");
        } catch { process.stdout.write(""); }
      });
    '
}

if is_enabled "${PINTO_PLUGIN_AUTO_INSTALL:-1}"; then
  PACK_VERSION="$(pack_version)"
  INSTALLED_VERSION="$(installed_version)"

  if [ -z "$INSTALLED_VERSION" ]; then
    echo "Installing Pinto plugin from image: $PLUGIN_PACK (version ${PACK_VERSION:-unknown})"
    node "$OPENCLAW_CLI" plugins install "npm-pack:$PLUGIN_PACK"
  elif is_enabled "${PINTO_PLUGIN_AUTO_UPDATE:-1}" \
    && [ -n "$PACK_VERSION" ] \
    && [ "$INSTALLED_VERSION" != "$PACK_VERSION" ]; then
    echo "Updating Pinto plugin: $INSTALLED_VERSION -> $PACK_VERSION"
    node "$OPENCLAW_CLI" plugins install --force "npm-pack:$PLUGIN_PACK"
  else
    echo "Pinto plugin up to date: $PLUGIN_ID@${INSTALLED_VERSION:-unknown}"
  fi

  node /usr/local/bin/bootstrap-pinto-channel.mjs

  if is_enabled "${PINTO_PLUGIN_AUTO_ENABLE:-1}"; then
    node "$OPENCLAW_CLI" plugins enable "$PLUGIN_ID" >/dev/null 2>&1 || true
  fi
fi

exec "$@"
