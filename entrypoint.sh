#!/bin/bash
set -e

# Pfad korrigiert, damit er mit den Erwartungen von ZeroClaw übereinstimmt
CONFIG_PATH="/zeroclaw-data/config.toml"

# Nur generieren, wenn Config nicht existiert oder FORCE_CONFIG=true gesetzt ist
if [ ! -f "$CONFIG_PATH" ] || [ "$FORCE_CONFIG" = "true" ]; then
    # Erstellt nur noch das workspace-Verzeichnis (und zeroclaw-data, falls nicht vorhanden)
    mkdir -p /zeroclaw-data/workspace

    cat > "$CONFIG_PATH" <<EOF
api_key = "${API_KEY:-}"
default_provider = "${PROVIDER:-openrouter}"
default_model = "${ZEROCLAW_MODEL:-anthropic/claude-sonnet-4-6}"
default_temperature = ${TEMPERATURE:-0.7}

[memory]
backend = "${MEMORY_BACKEND:-sqlite}"
auto_save = true
embedding_provider = "${EMBEDDING_PROVIDER:-none}"
vector_weight = 0.7
keyword_weight = 0.3

[gateway]
port = ${GATEWAY_PORT:-3000}
host = "0.0.0.0"
require_pairing = ${REQUIRE_PAIRING:-true}
allow_public_bind = true

[autonomy]
level = "${AUTONOMY_LEVEL:-supervised}"
workspace_only = true
allowed_commands = ["git", "npm", "cargo", "ls", "cat", "grep", "curl"]
forbidden_paths = ["/etc", "/root", "/proc", "/sys"]

[runtime]
kind = "native"

[browser]
enabled = ${BROWSER_ENABLED:-false}
allowed_domains = [${BROWSER_DOMAINS:-}]
backend = "${BROWSER_BACKEND:-rust_native}"
native_headless = true
native_webdriver_url = "http://127.0.0.1:9515"

[secrets]
encrypt = true

[tunnel]
provider = "none"
EOF

    echo "Config generated at $CONFIG_PATH"
fi

# Führt den an den Container übergebenen Befehl aus
exec "$@"
