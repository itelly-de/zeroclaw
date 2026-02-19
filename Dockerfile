# syntax=docker/dockerfile:1

# ── Stage 1: Build ZeroClaw ─────────────────────────────────────
FROM rust:1.85-slim-bookworm AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 1. Copy manifests to cache dependencies
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Copy workspace crates if they exist
COPY crates/ crates/

RUN cargo build --release --locked || cargo build --release
RUN rm -rf src

# 2. Copy full source and rebuild
COPY . .
RUN touch src/main.rs
RUN cargo build --release --locked || cargo build --release
RUN strip target/release/zeroclaw

# ── Stage 2: Runtime with full tooling ──────────────────────────
FROM debian:bookworm-slim AS runtime

# Install runtime dependencies:
# - bash/sh for terminal access
# - chromium + chromedriver for browser support
# - git for skills installation
# - ca-certificates for HTTPS
# - curl for debugging/health checks
# - sqlite3 for memory backend inspection
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    chromium \
    chromium-driver \
    curl \
    git \
    sqlite3 \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r zeroclaw && useradd -r -g zeroclaw -d /zeroclaw-data -s /bin/bash zeroclaw

# Create data directory
RUN mkdir -p /zeroclaw-data/.zeroclaw /zeroclaw-data/workspace \
    && chown -R zeroclaw:zeroclaw /zeroclaw-data

# Copy ZeroClaw binary
COPY --from=builder /app/target/release/zeroclaw /usr/local/bin/zeroclaw
RUN chmod +x /usr/local/bin/zeroclaw

# Environment
ENV HOME=/zeroclaw-data
ENV ZEROCLAW_HOME=/zeroclaw-data/.zeroclaw
ENV ZEROCLAW_WORKSPACE=/zeroclaw-data
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver
# Chromium flags for running in container (no GPU, no sandbox for container)
ENV CHROMIUM_FLAGS="--no-sandbox --headless --disable-gpu --disable-dev-shm-usage"

WORKDIR /zeroclaw-data
USER zeroclaw

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD ["zeroclaw", "doctor"]

EXPOSE 3000

# Use tini as init to handle signals properly
ENTRYPOINT ["tini", "--"]
CMD ["zeroclaw", "gateway"]
