#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
# APP: GNOME Keyring
#
# PURPOSE:
# Unlocks the keyring daemon so that apps like VS Code and SSH can store 
# and retrieve credentials without manual password prompts.
###############################################################################
set -e

log() { echo "[KEYRING-STARTUP] $*"; }

# Initialize the daemon for the current session
if command -v gnome-keyring-daemon > /dev/null; then
    log "Initializing GNOME Keyring (Secrets/SSH)..."
    # We export the variables so that subsequent shells see the agent
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK
fi
