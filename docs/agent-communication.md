# Agent Communication Notes

This repo exposes OpenClaw through Docker Compose. Agents can receive messages through configured channels.

## Pinto Channel

Default Pinto webhook path:

```text
/plugins/pinto/webhook
```

Example public webhook URL:

```text
https://your-domain.example/plugins/pinto/webhook
```

The Pinto channel starts only after `channels.pinto.botId` is configured.

Configure Pinto with CLI:

```bash
printf '%s\n' '{"channels":{"pinto":{"enabled":true,"apiUrl":"https://api.pinto-app.com","botId":"YOUR_PINTO_BOT_UUID","webhookSecret":"YOUR_WEBHOOK_SECRET","webhookPath":"/plugins/pinto/webhook"}}}' | docker compose run --rm -T openclaw-cli config patch --stdin
docker compose restart openclaw-gateway
```

Test webhook route:

```bash
curl -i https://your-domain.example/plugins/pinto/webhook
```

Expected:

```json
{"ok":true,"channel":"pinto"}
```

## Agent Session Links

OpenClaw chat URLs can include an agent session, for example:

```text
https://your-domain.example/chat?session=agent:main:pinto:direct:CHAT_ID
```

Replace:

- `main` with the OpenClaw agent id
- `pinto` with the channel id
- `CHAT_ID` with the external chat/session id

## Useful CLI Commands

List agents/channels/plugins:

```bash
docker compose run --rm openclaw-cli agents list
docker compose run --rm openclaw-cli channels list
docker compose run --rm openclaw-cli plugins list
```

Validate config:

```bash
docker compose run --rm openclaw-cli config validate
```

Approve browser/device:

```bash
docker compose run --rm openclaw-cli devices list
docker compose run --rm openclaw-cli devices approve DEVICE_ID
```

## GitHub Actions Idea

For GitHub Actions build notifications, use a GitHub webhook with event:

```text
workflow_run
```

Watch for:

```text
action = completed
```

Useful fields:

```text
repository.full_name
workflow_run.name
workflow_run.conclusion
workflow_run.html_url
workflow_run.head_branch
workflow_run.head_sha
```

Recommended long-term approach: create a small OpenClaw plugin or bridge service that receives GitHub webhooks, verifies `X-Hub-Signature-256`, and sends a message into the target OpenClaw agent.

