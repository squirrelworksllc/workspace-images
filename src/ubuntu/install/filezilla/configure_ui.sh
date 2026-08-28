#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Deploys FileZilla XML config and Desktop integration
###############################################################################
set -euo pipefail

log() { echo "[FILEZILLA-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Step 1: Deploying pre-baked FileZilla configuration..."
CONF_DIR="$KASM_HOME/.config/filezilla"
mkdir -p "$CONF_DIR"

if [ -f "$SCRIPT_DIR/filezilla.xml" ]; then
    cp "$SCRIPT_DIR/filezilla.xml" "$CONF_DIR/filezilla.xml"
    
    # Force 'Disable update check' to 1 (true) to prevent nagware
    sed -i 's/<Setting name="Disable update check">0/<Setting name="Disable update check">1/g' "$CONF_DIR/filezilla.xml"
    # Update the Greeting Version to keep the app from thinking it's the first run
    sed -i "s/<Setting name=\"Greeting version\">.*<\/Setting>/<Setting name=\"Greeting version\">3.99.9<\/Setting>/g" "$CONF_DIR/filezilla.xml"
fi

log "Step 2: Deploying Desktop Shortcut..."
SRC_DESKTOP="/usr/share/applications/filezilla.desktop"
if [ -f "$SRC_DESKTOP" ]; then
    mkdir -p "$KASM_HOME/Desktop"
    cp "$SRC_DESKTOP" "$KASM_HOME/Desktop/filezilla.desktop"
    chmod +x "$KASM_HOME/Desktop/filezilla.desktop"
    chown -R 1000:0 "$KASM_HOME/Desktop" 2>/dev/null || true
fi

chown -R 1000:0 "$CONF_DIR" 2>/dev/null || true

log "FileZilla UI configuration complete."
