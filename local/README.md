# Local Development Setup

## Quick Start

1. Copy the example files:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your API keys and tokens

3. Start Clawdbot:
   ```bash
   source .env && docker run -d \
     --name clawdbot-local \
     -p 18789:18789 \
     -p 18790:18790 \
     -e MINIMAX_API_KEY="$MINIMAX_API_KEY" \
     -e TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" \
     -e TELEGRAM_ALLOWED_USERS="$TELEGRAM_ALLOWED_USERS" \
     -e WHATSAPP_ENABLED="$WHATSAPP_ENABLED" \
     -e CLAWDBOT_GATEWAY_TOKEN="$CLAWDBOT_GATEWAY_TOKEN" \
     -v clawdbot-data:/root/.clawdbot \
     -v clawdbot-workspace:/root/clawd \
     ghcr.io/zot24/clawdbot-docker:latest
   ```

4. (WhatsApp only) Link your WhatsApp account:
   ```bash
   docker exec -it clawdbot-local node dist/index.js channels login
   ```
   Scan the QR code with WhatsApp on your phone. Credentials are stored in the volume.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MINIMAX_API_KEY` | Yes* | MiniMax API key for M2.1 model |
| `ANTHROPIC_API_KEY` | Yes* | Anthropic API key for Claude |
| `TELEGRAM_BOT_TOKEN` | No | Telegram bot token from @BotFather |
| `TELEGRAM_ALLOWED_USERS` | No | Comma-separated Telegram user IDs to pre-approve |
| `CLAWDBOT_DM_POLICY` | No | `pairing` (default) or `open` |
| `WHATSAPP_ENABLED` | No | Set to `true` to enable WhatsApp channel |
| `WHATSAPP_DM_POLICY` | No | `pairing` (default), `allowlist`, `open`, or `disabled` |
| `WHATSAPP_GROUP_POLICY` | No | `disabled` (default), `open`, or `allowlist` |
| `WHATSAPP_ALLOWED_NUMBERS` | No | Comma-separated phone numbers (e.g., `+15551234567`) |
| `WHATSAPP_GROUPS` | No | Comma-separated group IDs, or `*` for all groups |
| `CLAWDBOT_GATEWAY_TOKEN` | No | Auth token for WebChat (auto-generated if not set) |

\* At least one LLM provider key required

## Files

- `.env.example` - Template (safe to share)
- `.env` - Your secrets (gitignored)

## Commands

Stop:
```bash
docker stop clawdbot-local
```

View logs:
```bash
docker logs -f clawdbot-local
```

Restart:
```bash
docker restart clawdbot-local
```

Approve Telegram pairing:
```bash
docker exec clawdbot-local node dist/index.js pairing approve telegram <CODE>
```

Link WhatsApp (scan QR code):
```bash
docker exec -it clawdbot-local node dist/index.js channels login
```

## Access

- **WebChat UI**: http://localhost:18789/chat
- **Gateway WebSocket**: ws://localhost:18789

## Building Locally

To test changes to the Docker image:
```bash
cd ..
docker build -t clawdbot:local .
```

Then use `clawdbot:local` instead of `ghcr.io/zot24/clawdbot-docker:latest`.
