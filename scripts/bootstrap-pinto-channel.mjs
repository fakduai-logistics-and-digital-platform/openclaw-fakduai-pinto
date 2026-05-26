import { randomBytes } from "node:crypto";
import { dirname } from "node:path";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";

const configPath =
  process.env.OPENCLAW_CONFIG_PATH || "/home/node/.openclaw/openclaw.json";

const defaultPintoConfig = () => ({
  enabled: true,
  apiUrl: "https://api.pinto-app.com",
  botId: "",
  agentId: "",
  webhookSecret: `pinto-oc-${randomBytes(12).toString("hex")}`,
  webhookPath: "/plugins/pinto/webhook",
});

const publicOrigin = () => {
  const raw = process.env.PUBLIC_OPENCLAW_URL?.trim();
  if (!raw || raw.includes("REPLACE-WITH-TRYCLOUDFLARE-URL")) {
    return undefined;
  }
  try {
    return new URL(raw).origin;
  } catch {
    return undefined;
  }
};

const gatewayToken = () => {
  const raw = process.env.OPENCLAW_GATEWAY_TOKEN?.trim();
  if (!raw || raw === "change-me-long-random-token") {
    return undefined;
  }
  return raw;
};

mkdirSync(dirname(configPath), { recursive: true });

let config = {};
if (existsSync(configPath)) {
  const raw = readFileSync(configPath, "utf8").trim();
  if (raw) {
    try {
      config = JSON.parse(raw);
    } catch (error) {
      console.error(
        `Cannot update ${configPath}: expected JSON. ${error instanceof Error ? error.message : String(error)}`,
      );
      process.exit(1);
    }
  }
}

if (!config || typeof config !== "object" || Array.isArray(config)) {
  config = {};
}

const root = config;

let changed = false;

if (
  !root.gateway ||
  typeof root.gateway !== "object" ||
  Array.isArray(root.gateway)
) {
  root.gateway = {};
  changed = true;
}

if (!root.gateway.mode) {
  root.gateway.mode = "local";
  changed = true;
}

if (!root.gateway.bind) {
  root.gateway.bind = "lan";
  changed = true;
}

if (
  !root.gateway.auth ||
  typeof root.gateway.auth !== "object" ||
  Array.isArray(root.gateway.auth)
) {
  root.gateway.auth = {};
  changed = true;
}

const token = gatewayToken();
if (token) {
  if (root.gateway.auth.mode !== "token") {
    root.gateway.auth.mode = "token";
    changed = true;
  }

  if (root.gateway.auth.token !== token) {
    root.gateway.auth.token = token;
    changed = true;
  }

  if (root.gateway.auth.password !== undefined) {
    delete root.gateway.auth.password;
    changed = true;
  }
}

if (
  !root.gateway.controlUi ||
  typeof root.gateway.controlUi !== "object" ||
  Array.isArray(root.gateway.controlUi)
) {
  root.gateway.controlUi = {};
  changed = true;
}

if (!Array.isArray(root.gateway.controlUi.allowedOrigins)) {
  root.gateway.controlUi.allowedOrigins = [
    "http://localhost:18789",
    "http://127.0.0.1:18789",
  ];
  changed = true;
}

const origin = publicOrigin();
if (origin && !root.gateway.controlUi.allowedOrigins.includes(origin)) {
  root.gateway.controlUi.allowedOrigins.push(origin);
  changed = true;
}

if (
  !root.channels ||
  typeof root.channels !== "object" ||
  Array.isArray(root.channels)
) {
  root.channels = {};
}

if (!root.channels.pinto) {
  root.channels.pinto = defaultPintoConfig();
  changed = true;
  console.log(`Initialized channels.pinto in ${configPath}`);
}

if (changed) {
  writeFileSync(configPath, `${JSON.stringify(root, null, 2)}\n`);
  console.log(`Updated OpenClaw Docker defaults in ${configPath}`);
}
