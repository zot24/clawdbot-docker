# Clawdbot Docker Image

Docker image for [Clawdbot](https://github.com/clawdbot/clawdbot) - your personal AI assistant.

Built for use with [Umbrel](https://umbrel.com) and other self-hosted platforms.

## Quick Start

### Using Docker Compose (Recommended)

1. Clone this repository
2. Copy `.env.example` to `.env` and add your API keys
3. Run:

```bash
docker compose up -d
```

4. Open http://localhost:18789/chat

### Using Docker Run

```bash
docker run -d \
  -p 18789:18789 \
  -e ANTHROPIC_API_KEY=your-key \
  -e TELEGRAM_BOT_TOKEN=your-bot-token \
  -v clawdbot-data:/home/clawdbot/.clawdbot \
  -v clawdbot-workspace:/home/clawdbot/clawd \
  ghcr.io/zot24/clawdbot-docker:latest
```

## Supported Channels

| Channel | Environment Variables | Notes |
|---------|----------------------|-------|
| **Telegram** | `TELEGRAM_BOT_TOKEN` | Get token from @BotFather |
| **WhatsApp** | `WHATSAPP_ENABLED=true` | Requires QR code linking |
| **Discord** | `DISCORD_BOT_TOKEN` | From Discord Developer Portal |
| **Slack** | `SLACK_APP_TOKEN`, `SLACK_BOT_TOKEN` | Socket mode required |
| **MS Teams** | `MSTEAMS_APP_ID`, `MSTEAMS_APP_PASSWORD` | Azure AD app registration |
| **Signal** | `SIGNAL_NUMBER` | Requires signal-cli (not included) |

## Supported LLM Providers

| Provider | Environment Variables | Model Example |
|----------|----------------------|---------------|
| **Anthropic** | `ANTHROPIC_API_KEY` | `anthropic/claude-sonnet-4` |
| **MiniMax** | `MINIMAX_API_KEY` | `minimax/MiniMax-M2.1` |
| **OpenAI** | `OPENAI_API_KEY` | `openai/gpt-4o` |
| **OpenRouter** | `OPENROUTER_API_KEY` | `openrouter/anthropic/claude-sonnet-4` |
| **Moonshot** | `MOONSHOT_API_KEY` | `moonshot/moonshot-v1-128k` |
| **GLM** | `GLM_API_KEY` | `glm/glm-4-plus` |
| **Local (Ollama, etc.)** | `OPENCODE_BASE_URL` | `opencode/llama3.1` |

The image auto-selects a model based on available API keys. Override with `CLAWDBOT_MODEL`.

## Environment Variables

### LLM Providers

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | One provider required | Anthropic API key |
| `MINIMAX_API_KEY` | | MiniMax API key |
| `OPENAI_API_KEY` | | OpenAI API key |
| `OPENAI_ORG_ID` | | OpenAI organization ID |
| `OPENAI_BASE_URL` | | OpenAI-compatible endpoint |
| `OPENROUTER_API_KEY` | | OpenRouter API key |
| `MOONSHOT_API_KEY` | | Moonshot API key |
| `GLM_API_KEY` | | GLM/ChatGLM API key |
| `OPENCODE_BASE_URL` | | Local model endpoint (e.g., Ollama) |
| `OPENCODE_API_KEY` | | API key for local endpoint |
| `OPENCODE_MODEL` | | Model name for local provider |
| `CLAWDBOT_MODEL` | | Override auto-selected model |

### Channels

| Variable | Default | Description |
|----------|---------|-------------|
| `TELEGRAM_BOT_TOKEN` | | Telegram bot token |
| `TELEGRAM_ALLOWED_USERS` | | Comma-separated user IDs |
| `CLAWDBOT_DM_POLICY` | `pairing` | DM policy: pairing, allowlist, open |
| `WHATSAPP_ENABLED` | `false` | Enable WhatsApp channel |
| `WHATSAPP_DM_POLICY` | `pairing` | DM policy |
| `WHATSAPP_GROUP_POLICY` | `disabled` | Group policy: disabled, allowlist |
| `WHATSAPP_ALLOWED_NUMBERS` | | Comma-separated phone numbers |
| `WHATSAPP_GROUPS` | | Group IDs or `*` for all |
| `DISCORD_BOT_TOKEN` | | Discord bot token |
| `DISCORD_ALLOWED_USERS` | | Comma-separated user IDs |
| `DISCORD_DM_POLICY` | `pairing` | DM policy |
| `SLACK_APP_TOKEN` | | Slack app token (xapp-...) |
| `SLACK_BOT_TOKEN` | | Slack bot token (xoxb-...) |
| `SLACK_ALLOWED_USERS` | | Comma-separated user IDs |
| `MSTEAMS_APP_ID` | | Azure AD app ID |
| `MSTEAMS_APP_PASSWORD` | | Azure AD app password |
| `SIGNAL_NUMBER` | | Signal phone number |

### Gateway

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAWDBOT_GATEWAY_TOKEN` | Auto-generated | Authentication token |
| `CLAWDBOT_GATEWAY_PORT` | `18789` | Gateway port |
| `GATEWAY_MODE` | `local` | Gateway mode: local, cloud |
| `GATEWAY_BIND` | `lan` | Bind mode: lan, loopback, tailnet |

### Agent Runtime

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENT_TIMEOUT` | `600` | Agent timeout in seconds |
| `AGENT_TIMEZONE` | `UTC` | Timezone for agent |
| `ENABLE_MEMORY_SEARCH` | `false` | Enable memory search |
| `ENABLE_BROWSER` | `true` | Enable browser automation |
| `ENABLE_EXEC` | `true` | Enable shell execution |
| `EXEC_TIMEOUT` | `30000` | Exec timeout in milliseconds |

### Text-to-Speech (sag)

| Variable | Default | Description |
|----------|---------|-------------|
| `ELEVENLABS_API_KEY` | | ElevenLabs API key for TTS |
| `SAG_VOICE_ID` | | Default voice ID for sag |

### Data Directories

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAWDBOT_DATA_DIR` | `/home/clawdbot/.clawdbot` | Config and credentials |
| `CLAWDBOT_WORKSPACE` | `/home/clawdbot/clawd` | Workspace, memory, skills |

## Ports

- **18789**: Gateway (HTTP + WebSocket + WebChat at `/chat`)
- **18790**: Bridge (TCP for mobile nodes)

## Volumes

- `/home/clawdbot/.clawdbot`: Configuration and credentials
- `/home/clawdbot/clawd`: Workspace, memory, and skills

## Channel Setup

### Telegram

1. Message @BotFather on Telegram
2. Create a new bot with `/newbot`
3. Copy the bot token
4. Set `TELEGRAM_BOT_TOKEN=your-token`

### WhatsApp

1. Set `WHATSAPP_ENABLED=true`
2. Start the container
3. Run `docker exec -it <container> node dist/index.js channels login`
4. Scan the QR code with WhatsApp

### Discord

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application
3. Go to Bot section, create a bot
4. Copy the token and set `DISCORD_BOT_TOKEN=your-token`
5. Enable required intents (Message Content, etc.)
6. Invite bot to your server with appropriate permissions

### Slack

1. Create a new Slack App at [api.slack.com](https://api.slack.com/apps)
2. Enable Socket Mode
3. Add required scopes: `chat:write`, `app_mentions:read`, `im:history`, etc.
4. Install to workspace
5. Copy App Token (`xapp-...`) and Bot Token (`xoxb-...`)
6. Set both `SLACK_APP_TOKEN` and `SLACK_BOT_TOKEN`

### MS Teams

1. Register an app in Azure AD
2. Configure Bot Framework registration
3. Set `MSTEAMS_APP_ID` and `MSTEAMS_APP_PASSWORD`

## Using Local Models (Ollama)

To use Ollama running on your host machine:

```bash
docker run -d \
  -p 18789:18789 \
  -e OPENCODE_BASE_URL=http://host.docker.internal:11434/v1 \
  -e OPENCODE_MODEL=llama3.1 \
  -e TELEGRAM_BOT_TOKEN=your-token \
  -v clawdbot-data:/home/clawdbot/.clawdbot \
  -v clawdbot-workspace:/home/clawdbot/clawd \
  ghcr.io/zot24/clawdbot-docker:latest
```

## Security

This image runs as a dedicated non-root user (`clawdbot`, UID 1000) for enhanced security:

- **Principle of Least Privilege**: The container process has only the permissions it needs, not full root access
- **Container Escape Mitigation**: If an attacker exploits a vulnerability in the application, they gain limited user privileges rather than root
- **Host System Protection**: Volume mounts and any potential breakouts are constrained to non-root permissions
- **Compliance**: Many security frameworks (CIS Docker Benchmark, PCI-DSS) require or recommend non-root containers
- **Defense in Depth**: Adds another security layer on top of container isolation

The UID/GID can be customized at build time if needed:

```bash
docker build --build-arg CLAWDBOT_UID=1001 --build-arg CLAWDBOT_GID=1001 -t clawdbot:custom .
```

## Features

- **Browser Automation**: Playwright with Chromium for web scraping
- **Voice Messages**: FFmpeg for audio processing
- **Image Processing**: ImageMagick for image manipulation
- **Shell Execution**: Run commands via the exec tool
- **Memory Search**: Semantic search over conversation history
- **Text-to-Speech**: ElevenLabs TTS via [sag](https://github.com/steipete/sag)
- **Speech-to-Text**: OpenAI Whisper for transcription
- **MCP Tools**: mcporter for Model Context Protocol servers
- **Python Tools**: uv/uvx for running Python MCP tools
- **GitHub CLI**: gh for GitHub operations

## Building Locally

```bash
# Build with docker-compose
docker compose build

# Or build directly
docker build -t clawdbot:local .
```

The Dockerfile uses a multi-stage build for optimal caching:
1. **deps**: System packages, Go, Python, global tools (cached)
2. **builder**: Clone and build Clawdbot (rebuilds on version changes)
3. **runtime**: Final image with all tools

## Included Tools

| Tool | Purpose |
|------|---------|
| **Playwright + Chromium** | Browser automation and web scraping |
| **FFmpeg** | Audio/video processing |
| **ImageMagick** | Image manipulation |
| **sag** | ElevenLabs TTS CLI |
| **whisper** | OpenAI speech-to-text |
| **mcporter** | MCP server management |
| **uv/uvx** | Python tool runner |
| **gh** | GitHub CLI |
| **xvfb** | Virtual framebuffer for headless browsers |

## Image Size

The full-featured image is approximately 1.5-2GB due to:
- Node.js runtime
- Go runtime and sag binary
- Python and uv
- Chromium browser
- FFmpeg and ImageMagick
- Clawdbot and dependencies

## License

This Docker image builds [Clawdbot](https://github.com/clawdbot/clawdbot) from source.
See the original repository for licensing information.
