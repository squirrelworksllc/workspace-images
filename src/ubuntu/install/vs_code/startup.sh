#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
#
# APP: Visual Studio Code
#
# PURPOSE:
# Ensures the user's configuration and extension directories have the correct
# ownership and permissions to prevent launch failures.
###############################################################################
set -e

log() { echo "[VSCODE-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Synchronizing VS Code profile permissions..."

# 1. Target Directories
# .config/Code: Main app settings, databases, and cache
# .vscode: Extensions and marketplace metadata
PATHS=(
    "$KASM_HOME/.config/Code"
    "$KASM_HOME/.vscode"
)

for path in "${PATHS[@]}"; do
    if [ -d "$path" ]; then
        # -R ensures subfolders like 'User' and 'CachedData' are fixed
        chown -R 1000:0 "$path"
        chmod -R u+rw "$path"
    else
        # If directories don't exist yet, create them to prevent 
        # root-owned folders being created by the app later
        mkdir -p "$path"
        chown -R 1000:0 "$path"
    fi
done

log "VS Code permissions verified. Ready for launch."
