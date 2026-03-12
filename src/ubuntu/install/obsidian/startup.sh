#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
#
# APP: Obsidian
#
# PURPOSE:
# This script ensures the Obsidian configuration directory is writeable.
#
# WHY IS THIS NEEDED FOR THIS APP?
# 1. PERMISSIONS: Enforces ownership on ~/.config/obsidian to prevent 
#    sandbox and database lock errors during persistent sessions.
###############################################################################
set -e

log() { echo "[OBSIDIAN-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

# Enforce ownership on the config dir
if [ -d "$KASM_HOME/.config/obsidian" ]; then
    log "Syncing permissions for Obsidian configuration..."
    chown -R 1000:1000 "$KASM_HOME/.config/obsidian"
fi

log "Obsidian runtime initialization complete."
