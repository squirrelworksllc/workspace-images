#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Configures UI, Start Menu, and stability fixes for VLC.
###############################################################################
set -euo pipefail

log() { echo "[VLC-UI] $*"; }

# Kasm 1.18+ standard user home detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Configuring VLC UI and Start Menu..."

DESKTOP_FILE="/usr/share/applications/vlc.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    # 1. Start Menu Registration
    # Ensure it shows up in 'Multimedia' and 'Video' categories
    sed -i 's/Categories=.*/Categories=AudioVideo;Player;Recorder;Multimedia;/g' "$DESKTOP_FILE"

    # (VLC is not an Electron/Chromium app - it has no --no-sandbox flag and
    #  passing one makes the launcher fail, so we deliberately don't touch Exec.)

    # 2. Refresh Application Database
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    # 3. Create Desktop Shortcut
    log "Deploying Desktop shortcut to $KASM_HOME"
    mkdir -p "$KASM_HOME/Desktop"
    cp "$DESKTOP_FILE" "$KASM_HOME/Desktop/vlc.desktop"
    
    # Enable the 'Allow Launching' bit for XFCE/Ubuntu Noble
    chmod +x "$KASM_HOME/Desktop/vlc.desktop"
    chown 1000:0 "$KASM_HOME/Desktop/vlc.desktop" 2>/dev/null || true
    
    log "VLC UI configuration applied."
else
    log "WARNING: vlc.desktop not found at $DESKTOP_FILE. Skipping UI integration."
fi
