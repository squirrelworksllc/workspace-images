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
    log "Initializing GNOME Keyring..."
    
    # Start the daemon and capture environment variables
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK

    # 2. Automated Unlock/Creation Logic
    # Define the directory first to satisfy Step 3
    KEYRING_DIR="$HOME/.local/share/keyrings"
    mkdir -p "$KEYRING_DIR"

    # Merge inputs to satisfy ShellCheck SC2259
    { echo "kasm_user"; echo "login"; } | gnome-keyring-daemon --unlock

    # 3. Ensure the login keyring is the default
    if [ ! -f "$KEYRING_DIR/default" ]; then
        echo "login" > "$KEYRING_DIR/default"
    fi

    log "Keyring 'login' unlocked successfully."
else
    log "Error: gnome-keyring-daemon not found."
fi
