#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements, prevents Slack from auto-starting,
#          and keeps the Desktop clean.
# Architecture: SquirrelWorks 1.1 - Nuclear Autostart Prevention
###############################################################################
set -euo pipefail

log() { echo "[SLACK-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

DESKTOP_FILE="/usr/share/applications/slack.desktop"
SYSTEM_AUTOSTART="/etc/xdg/autostart/slack.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    log "Step 1: Applying --no-sandbox fix for Kasm compatibility..."
    # Slack is an Electron app; needs no-sandbox in restricted containers
    sed -i 's@Exec=/usr/bin/slack@Exec=/usr/bin/slack --no-sandbox@' "$DESKTOP_FILE"

    log "Step 2: Categorizing Start Menu entry..."
    sed -i 's/Categories=.*/Categories=Network;InstantMessaging;Chat;/g' "$DESKTOP_FILE"

    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    # Step 3: Clean Desktop Policy
    # We remove any existing shortcuts to keep the workspace professional.
    log "Step 3: Removing desktop shortcut to maintain clean workspace..."
    rm -f "$KASM_HOME/Desktop/slack.desktop"
    
    # Step 4: Nuclear Option - Remove System Autostart
    # Prevents Electron from firing up on session start.
    if [ -f "$SYSTEM_AUTOSTART" ]; then
        log "Step 4: Nuclear Strike - Removing $SYSTEM_AUTOSTART..."
        rm -f "$SYSTEM_AUTOSTART"
    else
        log "Step 4: No system autostart found. Skipping removal."
    fi

    # Step 5: Pre-emptive Profile Block
    # Placeholder to prevent Slack from re-writing an autostart on first run.
    log "Step 5: Masking autostart in kasm-default-profile..."
    AUTOSTART_DIR="$KASM_HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"

    cat <<EOF > "$AUTOSTART_DIR/slack.desktop"
[Desktop Entry]
Type=Application
Name=Slack
Exec=/usr/bin/slack --no-sandbox
X-GNOME-Autostart-enabled=false
Hidden=true
NoDisplay=true
EOF

    # Ensure ownership is correct for the Kasm default profile UID 1000
    chown -R 1000:1000 "$KASM_HOME/.config"

    log "Slack UI configuration (Nuclear/Clean-Desktop) complete."
else
    log "WARNING: slack.desktop not found at $DESKTOP_FILE. Check installation."
fi
