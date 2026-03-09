#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module (Chrome)
###############################################################################
set -e

log() { echo "[CHROME-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6)
CHROME_DIR="$KASM_HOME/.config/google-chrome"

if [ -d "$CHROME_DIR" ]; then
    log "Performing pre-launch profile maintenance..."
    
    # 1. Clear Singleton files (Your original logic)
    find "$CHROME_DIR" -name "Singleton*" -delete 2>/dev/null || true
    
    # 2. Patch Preferences (Your original sed logic)
    # This prevents the "Chrome didn't shut down correctly" annoying bar
    PREF_FILE="$CHROME_DIR/Default/Preferences"
    if [ -f "$PREF_FILE" ]; then
        sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' "$PREF_FILE" || true
        sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' "$PREF_FILE" || true
    fi

    # 3. Ensure permissions
    chown -R 1000:1000 "$CHROME_DIR"
fi
