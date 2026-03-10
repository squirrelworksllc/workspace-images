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
    
    # Start the daemon
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK

    # 2. Automated Unlock/Creation Logic
    # We target 'login' as it's the standard keyring name apps look for.
    KEYRING_DIR="$HOME/.local/share/keyrings"
    mkdir -p "$KEYRING_DIR"

    # Use 'kasm_user' as the default password (matches Kasm UID 1000 profile)
    # This pipe creates the keyring if missing and unlocks it if it exists.
    echo -n "kasm_user" | gnome-keyring-daemon --unlock <<EOF
login
EOF

    # 3. Ensure the login keyring is the default
    if [ ! -f "$KEYRING_DIR/default" ]; then
        echo "login" > "$KEYRING_DIR/default"
    fi

    log "Keyring 'login' unlocked successfully."
else
    log "Error: gnome-keyring-daemon not found."
fi
