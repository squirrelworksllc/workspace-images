#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module (Edge)
###############################################################################
set -e
log() { echo "[EDGE-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6)
EDGE_DIR="$KASM_HOME/.config/microsoft-edge"

if [ -d "$EDGE_DIR" ]; then
    log "Performing Edge profile maintenance..."
    
    # 1. Clear Singleton files
    find "$EDGE_DIR" -name "Singleton*" -delete 2>/dev/null || true
    
    # 2. Patch Preferences (Prevent crash bars)
    PREF_FILE="$EDGE_DIR/Default/Preferences"
    if [ -f "$PREF_FILE" ]; then
        sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' "$PREF_FILE" || true
        sed -i 's/"exit_type":"Crashed"/"exit_type":"None"/' "$PREF_FILE" || true
    fi

    chown -R 1000:1000 "$EDGE_DIR"
fi
