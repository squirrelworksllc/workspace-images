#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
#
# APP: Firefox
#
# PURPOSE:
# Cleans up stale profile locks and ensures profile ownership.
#
# WHY IS THIS NEEDED FOR THIS APP?
# 1. LOCK CLEANUP: Removes 'parent.lock' which prevents Firefox from starting
#    if a previous session was terminated unexpectedly.
# 2. PERMISSIONS: Ensures the .mozilla directory is writeable by the user.
###############################################################################
set -e

log() { echo "[FIREFOX-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

# 1. Permission Sync
if [ -d "$KASM_HOME/.mozilla" ]; then
    log "Syncing Firefox profile permissions..."
    # best-effort: custom_startup.sh may run unprivileged
    chown -R 1000:0 "$KASM_HOME/.mozilla" 2>/dev/null || true

    # 2. Lock Cleanup
    # Find and remove any stale lock files in any profile directory
    find "$KASM_HOME/.mozilla/firefox" -name "parent.lock" -delete 2>/dev/null || true
    log "Stale Firefox locks cleared."
fi
