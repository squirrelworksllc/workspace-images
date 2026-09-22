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
# (best-effort: custom_startup.sh may run unprivileged)
if [ -d "$KASM_HOME/.recoll" ]; then
    log "Syncing permissions for Recoll database..."
    chown -R 1000:0 "$KASM_HOME/.recoll" 2>/dev/null || true
fi

# 2. Start Background Indexing Monitor
# -m: Monitor mode (real-time indexing via inotify)
# -D: Run as a background daemon
if command -v recollindex > /dev/null && ! pgrep -x "recollindex" > /dev/null; then
    log "Starting Recoll real-time indexer daemon..."
    RECOLL_USER="$(id -un 1000 2>/dev/null || echo kasm-user)"
    if [ "$(id -u)" -eq 0 ] && command -v runuser >/dev/null 2>&1; then
        runuser -u "$RECOLL_USER" -- recollindex -m -D || log "WARNING: indexer failed to start."
    elif [ "$(id -u)" -eq 0 ] && command -v sudo >/dev/null 2>&1; then
        sudo -u "$RECOLL_USER" recollindex -m -D || log "WARNING: indexer failed to start."
    else
        # Already unprivileged (or no sudo/runuser) - just run it directly
        recollindex -m -D || log "WARNING: indexer failed to start."
    fi
fi

log "Recoll runtime initialization complete."
