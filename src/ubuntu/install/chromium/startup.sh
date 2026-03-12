#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module (Chromium)
###############################################################################
set -e
log() { echo "[CHROMIUM-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6)
CHROMIUM_DIR="$KASM_HOME/.config/chromium"

if [ -d "$CHROMIUM_DIR" ]; then
    log "Performing Chromium profile maintenance..."
    
    # Clear lock files that block launch
    find "$CHROMIUM_DIR" -name "Singleton*" -delete 2>/dev/null || true
    
    # Patch Preferences (same logic as Chrome)
    PREF_FILE="$CHROMIUM_DIR/Default/Preferences"
    if [ -f "$PREF_FILE" ]; then
        sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' "$PREF_FILE" || true
        sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' "$PREF_FILE" || true
    fi

    chown -R 1000:1000 "$CHROMIUM_DIR"
fi
