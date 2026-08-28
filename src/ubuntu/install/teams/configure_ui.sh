#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for teams-for-linux.
# Optimized for: Kasm 1.18+ / Ubuntu Noble
###############################################################################
set -euo pipefail

log() { echo "[TEAMS-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Configuring teams-for-linux UI elements..."

# Ensure directories exist
mkdir -p "$KASM_HOME/Desktop" 
mkdir -p "$KASM_HOME/.config/teams-for-linux"

DESKTOP_FILE="/usr/share/applications/teams-for-linux.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    # 1. Start Menu Registration & Sandbox Fix
    log "Applying Start Menu categorization and sandbox fix..."
    # Fix the Exec line for Kasm/Docker compatibility (idempotent)
    if ! grep -q -- '--no-sandbox' "$DESKTOP_FILE"; then
        sed -i 's@Exec=/usr/bin/teams-for-linux@Exec=/usr/bin/teams-for-linux --no-sandbox@' "$DESKTOP_FILE"
    fi
    # Ensure it appears in 'Internet' and 'Communication'
    sed -i 's/Categories=.*/Categories=Network;Chat;InstantMessaging;VideoConference;/g' "$DESKTOP_FILE"
    
    # 2. Refresh the System Menu Cache
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    # 3. FIX: Disable Autostart (Nuclear Option)
    log "Aggressively disabling auto-launch for Teams..."
    rm -f /etc/xdg/autostart/teams-for-linux.desktop
    rm -f /usr/share/autostart/teams-for-linux.desktop

    AUTOSTART_DIR="$KASM_HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"

    # Block Teams from stealing 400MB of RAM on boot
cat <<EOF > "$AUTOSTART_DIR/teams-for-linux.desktop"
[Desktop Entry]
Type=Application
Name=Teams for Linux
Exec=/usr/bin/teams-for-linux --no-sandbox
X-GNOME-Autostart-enabled=false
Hidden=true
NoDisplay=true
EOF

    # 4. Global Permissions Sync (Noble runs the session user with primary group 0)
    chown -R 1000:0 "$KASM_HOME/Desktop" 2>/dev/null || true
    chown -R 1000:0 "$KASM_HOME/.config" 2>/dev/null || true
    
    log "Teams UI configuration successfully applied."
else
    log "WARNING: Source desktop file not found at $DESKTOP_FILE."
fi
