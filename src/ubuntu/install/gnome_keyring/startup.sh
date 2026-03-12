#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
# APP: GNOME Keyring
#
# PURPOSE:
# Creates and unlocks the keyring daemon with a default password ('kasm_user')
# to suppress UI prompts for VS Code, Git, and Chrome.
###############################################################################
set -e

log() { echo "[KEYRING-STARTUP] $*"; }

# 1. Initialize the daemon and export env vars
if command -v gnome-keyring-daemon > /dev/null; then
    log "Initializing GNOME Keyring (SSH/PKCS11 only)..."
    
    # Start the daemon and capture environment variables (secrets disabled to stop popups)
    eval $(gnome-keyring-daemon --start --components=pkcs11,ssh)
    export SSH_AUTH_SOCK

    log "Keyring daemon started without secrets component."
else
    log "Error: gnome-keyring-daemon not found."
fi
