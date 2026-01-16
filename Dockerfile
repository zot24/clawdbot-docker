# Clawdbot Docker Image
# Builds Clawdbot from source for use with Umbrel and other self-hosted platforms

FROM node:22-bookworm-slim

# Install system dependencies
# - git, curl, ca-certificates: Build essentials
# - ffmpeg: Audio/voice processing for voice messages
# - imagemagick: Image manipulation and processing
# - Playwright dependencies: Chromium browser automation
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    ffmpeg \
    imagemagick \
    # Playwright/Chromium dependencies
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Set working directory
WORKDIR /app

# Clone Clawdbot repository
ARG CLAWDBOT_VERSION=main
RUN git clone --depth 1 --branch ${CLAWDBOT_VERSION} https://github.com/clawdbot/clawdbot.git .

# Install dependencies
RUN pnpm install --frozen-lockfile || pnpm install

# Build the application
RUN pnpm build

# Build the UI assets (Control Panel, WebChat)
RUN pnpm ui:build

# Install Playwright Chromium for browser automation
# This enables the browser tool for web scraping/automation
RUN npx playwright install chromium

# Create data directories
RUN mkdir -p /root/.clawdbot /root/clawd

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
# 18789: Gateway (HTTP + WebSocket + WebChat at /chat)
# 18790: Bridge (TCP for mobile nodes)
EXPOSE 18789 18790

# Set environment
ENV NODE_ENV=production

# Health check (gateway serves HTTP on 18789)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["gateway"]
