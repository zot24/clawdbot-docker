#!/bin/bash
set -e

CONFIG_DIR="${CLAWDBOT_DATA_DIR:-/root/.clawdbot}"
CONFIG_FILE="${CONFIG_DIR}/clawdbot.json"
WORKSPACE="${CLAWDBOT_WORKSPACE:-/root/clawd}"

# Create directories if they don't exist
mkdir -p "${CONFIG_DIR}" "${WORKSPACE}" "${WORKSPACE}/memory" "${WORKSPACE}/skills"

# Generate configuration if it doesn't exist or if Telegram token changed
generate_config() {
    echo "Generating Clawdbot configuration..."

    # Build Telegram configuration
    local TELEGRAM_ENABLED="false"
    local TELEGRAM_TOKEN=""
    local TELEGRAM_DM_POLICY="${CLAWDBOT_DM_POLICY:-pairing}"
    local TELEGRAM_ALLOW_FROM=""
    if [ -n "${TELEGRAM_BOT_TOKEN}" ]; then
        TELEGRAM_ENABLED="true"
        TELEGRAM_TOKEN="${TELEGRAM_BOT_TOKEN}"
    fi

    # Build allowFrom line if TELEGRAM_ALLOWED_USERS is set (comma-separated user IDs)
    local TELEGRAM_ALLOW_LINE=""
    if [ -n "${TELEGRAM_ALLOWED_USERS}" ]; then
        # Convert comma-separated IDs to JSON array
        local ALLOW_ARRAY=$(echo "${TELEGRAM_ALLOWED_USERS}" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
        TELEGRAM_ALLOW_LINE=",\"allowFrom\": [${ALLOW_ARRAY}]"
    fi

    # Generate auth token if not provided (exported for use in WebChat injection)
    AUTH_TOKEN="${CLAWDBOT_GATEWAY_TOKEN:-$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)}"

    # Validate token is alphanumeric only (security: prevents injection in HTML/JS)
    if [[ ! "${AUTH_TOKEN}" =~ ^[a-zA-Z0-9]+$ ]]; then
        echo "ERROR: Auth token must be alphanumeric only. Invalid characters found."
        exit 1
    fi

    # Determine model configuration based on available API keys
    local MODEL_CONFIG=""
    local MODELS_SECTION=""

    if [ -n "${MINIMAX_API_KEY}" ]; then
        # Use MiniMax as primary model
        MODEL_CONFIG='"model": { "primary": "minimax/MiniMax-M2.1" }'
        MODELS_SECTION=',
  "models": {
    "mode": "merge",
    "providers": {
      "minimax": {
        "baseUrl": "https://api.minimax.io/anthropic",
        "apiKey": "'"${MINIMAX_API_KEY}"'",
        "api": "anthropic-messages",
        "models": [
          {
            "id": "MiniMax-M2.1",
            "name": "MiniMax M2.1",
            "reasoning": false,
            "input": ["text"],
            "cost": {
              "input": 15,
              "output": 60,
              "cacheRead": 2,
              "cacheWrite": 10
            },
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  }'
    else
        # Default to Anthropic
        MODEL_CONFIG='"model": "anthropic/claude-opus-4-5"'
    fi

    # Write configuration file
    # Note: WebChat UI is served by Gateway on port 18789 at /chat
    # bind: "lan" required to expose outside container (default is loopback)
    cat > "${CONFIG_FILE}" <<EOF
{
  "gateway": {
    "mode": "local",
    "port": ${CLAWDBOT_GATEWAY_PORT:-18789},
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "${AUTH_TOKEN}"
    }
  },
  "channels": {
    "telegram": {
      "enabled": ${TELEGRAM_ENABLED},
      "botToken": "${TELEGRAM_TOKEN}",
      "dmPolicy": "${TELEGRAM_DM_POLICY}",
      "streamMode": "partial"${TELEGRAM_ALLOW_LINE}
    },
    "whatsapp": {
      "enabled": false
    },
    "discord": {
      "enabled": false
    },
    "slack": {
      "enabled": false
    },
    "signal": {
      "enabled": false
    }
  },
  "agents": {
    "defaults": {
      ${MODEL_CONFIG},
      "workspace": "${WORKSPACE}",
      "timeoutSeconds": 600,
      "memorySearch": {
        "enabled": false
      }
    }
  },
  "skills": {
    "entries": {}
  }${MODELS_SECTION}
}
EOF
    echo "Configuration generated at ${CONFIG_FILE}"
}

# Always regenerate config to pick up env var changes
generate_config

# Check if Telegram is configured
if [ -n "${TELEGRAM_BOT_TOKEN}" ]; then
    echo "Telegram bot token configured - Telegram channel enabled"
else
    echo "NOTE: No TELEGRAM_BOT_TOKEN set. Telegram channel disabled."
    echo "To enable Telegram:"
    echo "  1. Create a bot via @BotFather on Telegram"
    echo "  2. Copy the bot token"
    echo "  3. Set TELEGRAM_BOT_TOKEN environment variable"
fi

# Check for API keys
if [ -n "${MINIMAX_API_KEY}" ]; then
    echo "MiniMax API key configured - using MiniMax M2.1 model"
elif [ -n "${ANTHROPIC_API_KEY}" ]; then
    echo "Anthropic API key configured - using Claude models"
else
    echo "WARNING: No MINIMAX_API_KEY or ANTHROPIC_API_KEY set. Models will not work."
    echo "Set MINIMAX_API_KEY or ANTHROPIC_API_KEY environment variable."
fi

# Create default workspace files if they don't exist
if [ ! -f "${WORKSPACE}/SOUL.md" ]; then
    cat > "${WORKSPACE}/SOUL.md" <<EOF
# Soul

You are a helpful AI assistant running on Umbrel.
You are friendly, concise, and helpful.
EOF
fi

if [ ! -f "${WORKSPACE}/MEMORY.md" ]; then
    cat > "${WORKSPACE}/MEMORY.md" <<EOF
# Long-term Memory

This file stores durable facts and preferences.
EOF
fi

echo "Starting Clawdbot..."
echo "  Gateway port: ${CLAWDBOT_GATEWAY_PORT:-18789}"
echo "  WebChat UI: http://localhost:${CLAWDBOT_GATEWAY_PORT:-18789}/chat"

# Inject auth token into WebChat UI so it can connect to the gateway
# The WebChat stores settings (including token) in localStorage under a specific key
# We inject a script that pre-populates the token before the app loads
WEBCHAT_INDEX="/app/dist/control-ui/index.html"
if [ -f "${WEBCHAT_INDEX}" ]; then
    # Inject script that sets the token in localStorage before the app initializes
    # The app reads settings from localStorage and uses the token for WebSocket auth
    INJECT_SCRIPT="<script>(function(){try{var k='clawdbot.control.settings.v1',s=localStorage.getItem(k),o=s?JSON.parse(s):{};if(!o.token){o.token='${AUTH_TOKEN}';localStorage.setItem(k,JSON.stringify(o));}}catch(e){}})();</script>"
    sed -i "s|</head>|${INJECT_SCRIPT}</head>|" "${WEBCHAT_INDEX}"
    echo "  Auth token injected into WebChat UI"
fi

# Start the gateway
cd /app
exec node dist/index.js gateway
