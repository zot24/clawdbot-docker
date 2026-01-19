#!/bin/bash
# Check for new Clawdbot releases and notify via Telegram

REPO="clawdbot/clawdbot"
STATE_FILE="/root/.clawdbot/latest_release"
TELEGRAM_CHAT_ID="740109706"
TELEGRAM_BOT_TOKEN="8546397018:AAFFjEaUUlqxnLKfPgxw1DTngU5nYiXCd0"

# Get latest release
LATEST=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
RELEASE_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"html_url"' | cut -d'"' -f4)

# Get last known release
if [ -f "$STATE_FILE" ]; then
    LAST=$(cat "$STATE_FILE")
else
    LAST=""
fi

# Check if new release
if [ "$LATEST" != "$LAST" ] && [ -n "$LATEST" ]; then
    echo "New release detected: $LATEST"
    
    # Save new release
    echo "$LATEST" > "$STATE_FILE"
    
    # Send Telegram notification
    MESSAGE="🚀 New Clawdbot Release: $LATEST%0A%0AView: $RELEASE_URL"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$MESSAGE" \
        -d "parse_mode=HTML"
    
    echo "Notification sent!"
else
    echo "No new release. Current: $LATEST"
fi
