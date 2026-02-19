#!/bin/bash
set -e

# Pfade definieren
CONFIG_PATH="/zeroclaw-data/config.toml"
mkdir -p /zeroclaw-data/workspace

# ZWINGE die Umgebungsvariablen (Doppel-Unterstrich für Nested Config)
export ZEROCLAW_GATEWAY__ALLOW_PUBLIC_BIND=true
export ZEROCLAW_GATEWAY__HOST=0.0.0.0
export ZEROCLAW_GATEWAY__PORT=${GATEWAY_PORT:-3000}

# Generiere die Datei trotzdem zur Sicherheit
cat > "$CONFIG_PATH" <<EOF
api_key = "${API_KEY:-}"
default_provider = "${PROVIDER:-openrouter}"
default_model = "${ZEROCLAW_MODEL:-anthropic/claude-sonnet-4-6}"
default_temperature = ${TEMPERATURE:-0.7}

[memory]
backend = "${MEMORY_BACKEND:-sqlite}"
auto_save = true
embedding_provider = "${EMBEDDING_PROVIDER:-none}"

[gateway]
port = ${GATEWAY_PORT:-3000}
host = "0.0.0.0"
require_pairing = ${REQUIRE_PAIRING:-true}
allow_public_bind = true

[autonomy]
level = "${AUTONOMY_LEVEL:-supervised}"
workspace_only = true
allowed_commands = ["git", "npm", "cargo", "ls", "cat", "grep", "curl"]

[runtime]
kind = "native"

[browser]
enabled = ${BROWSER_ENABLED:-false}

[secrets]
encrypt = true

[tunnel]
provider = "none"
EOF

echo "🚀 Anti-Lockout: Environment variables set and config forced."
echo "Binding to: $ZEROCLAW_GATEWAY__HOST:$ZEROCLAW_GATEWAY__PORT"

# Führt das Programm aus
exec "$@"
