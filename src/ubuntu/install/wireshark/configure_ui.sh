#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Configures Wireshark groups, UI elements, and Start Menu.
###############################################################################
set -euo pipefail

log() { echo "[wireshark-ui] $*"; }

# Kasm 1.18+ standard user home detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Configuring Wireshark permissions and UI..."

# 1. FIX: Non-Root Capture Permissions
# Add the Kasm user to the wireshark group so they can see interfaces
if getent group wireshark > /dev/null; then
    usermod -aG wireshark kasm-user 2>/dev/null || true
    usermod -aG wireshark "$(id -nu 1000)" 2>/dev/null || true
    # Set capabilities on dumpcap so it can capture without root
    chgrp wireshark /usr/bin/dumpcap
    chmod 750 /usr/bin/dumpcap
    setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
    log "Permissions updated: UID 1000 can now capture packets without sudo."
fi

# 2. Start Menu
DESKTOP_FILE="/usr/share/applications/wireshark.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    log "Categorizing Wireshark for the Applications Menu..."
    sed -i 's/Categories=.*/Categories=Network;Monitor;Security;System;/g' "$DESKTOP_FILE"
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi
fi

# 3. Desktop icon (opt-in via WIRESHARK_DESKTOP_ICON=true; default off)
desktop_icon wireshark "$DESKTOP_FILE" false

log "Wireshark UI configuration complete."
