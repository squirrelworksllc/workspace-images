#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Configures UI, Start Menu, and stability fixes for VLC.
###############################################################################
set -euo pipefail

log() { echo "[VLC-UI] $*"; }

# Kasm 1.18+ standard user home detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Configuring VLC UI and Start Menu..."

DESKTOP_FILE="/usr/share/applications/vlc.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    # Ensure it shows up in 'Multimedia' and 'Video' categories.
    sed -i 's/Categories=.*/Categories=AudioVideo;Player;Recorder;Multimedia;/g' "$DESKTOP_FILE"
    # (VLC is not an Electron/Chromium app - it has no --no-sandbox flag and
    #  passing one makes the launcher fail, so we deliberately don't touch Exec.)
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi
else
    log "WARNING: vlc.desktop not found at $DESKTOP_FILE."
fi

# Desktop icon (opt-in via VLC_DESKTOP_ICON=true; default off)
desktop_icon vlc "$DESKTOP_FILE" false
