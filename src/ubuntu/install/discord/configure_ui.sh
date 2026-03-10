#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Discord sandbox fixing and SquirrelWorks UI standardization
# Architecture: SquirrelWorks 1.1 - Clean Desktop & Nuclear Autostart
###############################################################################
set -euo pipefail

log() { echo "[DISCORD-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

DESKTOP_FILE="/usr/share/applications/discord.desktop"
SYSTEM_AUTOSTART="/etc/xdg/autostart/discord.desktop"

log "Patching Discord for Container Sandboxing..."
if [ -f "$DESKTOP_FILE" ]; then
    # Step 1: Inject --no-sandbox into the system-wide desktop entry
    # Electron apps in Kasm containers require this to initialize correctly.
    sed -i 's@Exec=/usr/share/discord/Discord@Exec=/usr/share/discord/Discord --no-sandbox@g' "$DESKTOP_FILE"

    # Step 2: Categorizing for Start Menu
    sed -i 's/Categories=.*/Categories=Network;InstantMessaging;Chat;/g' "$DESKTOP_FILE"

    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    # Step 3: Clean Desktop Policy
    # Removing shortcut from $KASM_HOME/Desktop to keep the workspace professional.
    log "Step 3: Removing desktop shortcut..."
    rm -f "$KASM_HOME/Desktop/discord.desktop"

    # Step 4: Nuclear Option - Remove System Autostart
    # Discord is notorious for auto-launching; we purge the entry from /etc/xdg.
    if [ -f "$SYSTEM_AUTOSTART" ]; then
        log "Step 4: Nuclear Strike - Removing $SYSTEM_AUTOSTART..."
        rm -f "$SYSTEM_AUTOSTART"
    fi

    # Step 5: Pre-emptive Profile Block
    # Masking autostart in the user profile to prevent Discord from re-enabling it.
    log "Step 5: Masking autostart in kasm-default-profile..."
    AUTOSTART_DIR="$KASM_HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"

    cat <<EOF > "$AUTOSTART_DIR/discord.desktop"
[Desktop Entry]
Type=Application
Name=Discord
Exec=/usr/share/discord/Discord --no-sandbox
X-GNOME-Autostart-enabled=false
Hidden=true
NoDisplay=true
EOF

    # Ensure ownership is correct for the Kasm default profile (UID 1000)
    chown -R 1000:1000 "$KASM_HOME/.config"

    log "Discord UI configuration (Nuclear/Clean-Desktop) complete."
else
    log "WARNING: discord.desktop not found at $DESKTOP_FILE. Check installation."
fi
