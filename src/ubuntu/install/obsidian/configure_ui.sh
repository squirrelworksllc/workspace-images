#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Obsidian sandbox fixing and Desktop integration
###############################################################################
set -euo pipefail

log() { echo "[OBSIDIAN-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Step 1: Patching Obsidian for Container Sandboxing..."
DESKTOP_FILE="/usr/share/applications/obsidian.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    # Inject --no-sandbox into the Exec line (idempotent)
    if ! grep -q -- '--no-sandbox' "$DESKTOP_FILE"; then
        sed -i 's@Exec=/usr/bin/obsidian@Exec=/usr/bin/obsidian --no-sandbox@g' "$DESKTOP_FILE"
    fi
fi

# Desktop icon (opt-in via OBSIDIAN_DESKTOP_ICON=true; default off)
desktop_icon obsidian "$DESKTOP_FILE" false
