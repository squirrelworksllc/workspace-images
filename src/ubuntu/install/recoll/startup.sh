#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
#
# APP: Recoll (Full-Text Search)
#
# PURPOSE:
# This script initializes the Recoll indexing daemon and ensures the local
# database is writeable by the Kasm user.
#
# WHY IS THIS NEEDED FOR THIS APP?
# 1. DAEMONS: Starts 'recollindex -m -D' to provide real-time file indexing
#    as the analyst drops new samples or logs into the workspace.
# 2. PERMISSIONS: Enforces ownership on ~/.recoll to prevent "Database 
#    Locked" or "Permission Denied" errors during persistent sessions.
###############################################################################
set -e

log() { echo "[RECOLL-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

# 1. Permission Sync
# If ~/.recoll was created by root during a build or volume mount, the indexer fails.
if [ -d "$KASM_HOME/.recoll" ]; then
    log "Syncing permissions for Recoll database..."
    chown -R 1000:1000 "$KASM_HOME/.recoll"
fi

# 2. Start Background Indexing Monitor
# -m: Monitor mode (real-time indexing via inotify)
# -D: Run as a background daemon
if command -v recollindex > /dev/null; then
    # We check if it's already running to avoid duplicate processes on reconnect
    if ! pgrep -x "recollindex" > /dev/null; then
        log "Starting Recoll real-time indexer daemon..."
        # We run this as the Kasm user (1000) specifically
        sudo -u "$(id -un 1000)" recollindex -m -D
    else
        log "Recoll indexer is already running."
    fi
fi

log "Recoll runtime initialization complete."
