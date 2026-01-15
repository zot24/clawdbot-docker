# Local Development Setup

## Quick Start

1. Copy the example files:
   ```bash
   cp clawdbot.example.json clawdbot.json
   cp .env.example .env
   ```

2. Edit `.env` with your API keys

3. Edit `clawdbot.json` to enable channels you want

4. Start Clawdbot:
   ```bash
   # Load env vars and start
   source .env && clawdbot gateway --config ./clawdbot.json
   ```

## Files

- `clawdbot.example.json` - Template (safe to share)
- `clawdbot.json` - Your config (gitignored)
- `.env` - Your secrets (gitignored)

## Testing

Start gateway:
```bash
cd local
source .env && clawdbot gateway --config ./clawdbot.json
```

Login to WhatsApp (scan QR):
```bash
clawdbot channels login
```

Check status:
```bash
clawdbot status
```
