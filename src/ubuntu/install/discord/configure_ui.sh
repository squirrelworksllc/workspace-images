#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Discord sandbox fixing and Desktop integration
###############################################################################
set -euo pipefail

log() { echo "[DISCORD-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Patching Discord for Container Sandboxing..."
DESKTOP_FILE="/usr/share/applications/discord.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    # Inject --no-sandbox into the system-wide desktop entry
    sed -i 's@Exec=/usr/share/discord/Discord@Exec=/usr/share/discord/Discord --no-sandbox@g' "$DESKTOP_FILE"

    log "Deploying to Desktop..."
    mkdir -p "$KASM_HOME/Desktop"
    cp "$DESKTOP_FILE" "$KASM_HOME/Desktop/discord.desktop"
    chmod +x "$KASM_HOME/Desktop/discord.desktop"
    chown -R 1000:1000 "$KASM_HOME/Desktop"
fi
