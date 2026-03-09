#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Obsidian sandbox fixing and Desktop integration
###############################################################################
set -euo pipefail

log() { echo "[OBSIDIAN-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Step 1: Patching Obsidian for Container Sandboxing..."
DESKTOP_FILE="/usr/share/applications/obsidian.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    # Inject --no-sandbox into the Exec line
    sed -i 's@Exec=/usr/bin/obsidian@Exec=/usr/bin/obsidian --no-sandbox@g' "$DESKTOP_FILE"

    log "Step 2: Deploying to Desktop..."
    mkdir -p "$KASM_HOME/Desktop"
    cp "$DESKTOP_FILE" "$KASM_HOME/Desktop/obsidian.desktop"
    chmod +x "$KASM_HOME/Desktop/obsidian.desktop"
    chown -R 1000:1000 "$KASM_HOME/Desktop"
fi
