# Clawdbot Docker Image
# Multi-stage build for optimal caching and build times
# Stage 1: Heavy dependencies (cached, rarely changes)
# Stage 2: Build clawdbot (rebuilds on code changes)
# Stage 3: Runtime (final image with all tools)

# =============================================================================
# Stage 1: Dependencies
# Install all system packages and global tools that rarely change
# =============================================================================
FROM node:22-bookworm-slim AS deps

# Install system dependencies
# - Build essentials: git, curl, ca-certificates, wget
# - Media processing: ffmpeg, imagemagick
# - Browser automation: chromium and dependencies
# - Python tools: python3, pip
# - Utilities: gh (GitHub CLI), zip, unzip, tar
RUN apt-get update && apt-get install -y \
    # Build essentials
    git \
    curl \
    wget \
    ca-certificates \
    # GitHub CLI
    gh \
    # Media processing
    ffmpeg \
    imagemagick \
    # Python (for uvx/MCP tools)
    python3 \
    python3-pip \
    python3-venv \
    # Compression utilities
    zip \
    unzip \
    tar \
    gzip \
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
    # X11 for headless browser (optional, for VNC debugging)
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install Node.js global tools
RUN npm install -g mcporter

# Install Python tools (uv/uvx for running Python MCP tools)
RUN pip3 install --no-cache-dir --break-system-packages uv

# Set PATH for Python tools
ENV PATH="/root/.local/bin:${PATH}"

# Install Playwright Chromium browser
RUN npx -y playwright@latest install chromium

# =============================================================================
# Stage 2: Builder
# Clone and build Clawdbot (rebuilds when CLAWDBOT_VERSION changes)
# =============================================================================
FROM deps AS builder

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

# =============================================================================
# Stage 3: Runtime
# Final image with all tools and built application
# =============================================================================
FROM deps AS runtime

WORKDIR /app

# Copy built application from builder
COPY --from=builder /app /app

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
