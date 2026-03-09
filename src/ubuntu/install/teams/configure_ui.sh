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
    # Fix the Exec line for Kasm/Docker compatibility
    sed -i 's@Exec=/usr/bin/teams-for-linux@Exec=/usr/bin/teams-for-linux --no-sandbox@' "$DESKTOP_FILE"
    # Ensure it appears in 'Internet' and 'Communication'
    sed -i 's/Categories=.*/Categories=Network;Chat;InstantMessaging;VideoConference;/g' "$DESKTOP_FILE"
    
    # 2. Refresh the System Menu Cache
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    # 3. Desktop Shortcut Logic
    log "Deploying Desktop shortcut to $KASM_HOME"
    cp "$DESKTOP_FILE" "$KASM_HOME/Desktop/teams-for-linux.desktop"
    chmod +x "$KASM_HOME/Desktop/teams-for-linux.desktop"
    
    # 4. FIX: Disable Autostart at Session Login
    log "Disabling auto-launch to preserve session RAM..."
    AUTOSTART_DIR="$KASM_HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"

    # Block Teams from stealing 400MB of RAM on boot
cat <<EOF > "$AUTOSTART_DIR/teams-for-linux.desktop"
[Desktop Entry]
Type=Application
Name=Teams for Linux
Exec=/usr/bin/teams-for-linux --no-sandbox
X-GNOME-Autostart-enabled=false
NoDisplay=true
EOF

    # 5. Global Permissions Sync
    chown -R 1000:1000 "$KASM_HOME/Desktop"
    chown -R 1000:1000 "$KASM_HOME/.config"
    
    log "Teams UI configuration successfully applied."
else
    log "WARNING: Source desktop file not found at $DESKTOP_FILE."
fi
