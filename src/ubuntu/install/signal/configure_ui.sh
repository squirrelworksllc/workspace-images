#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements, sandboxing, and shortcuts for Signal.
###############################################################################
set -euo pipefail

log() { echo "[SIGNAL-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

DESKTOP_FILE="/usr/share/applications/signal-desktop.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    log "Step 1: Applying --no-sandbox fix for Kasm compatibility..."
    # Mandatory for Signal in most Kasm/Docker environments
    sed -i 's@Exec=/opt/Signal/signal-desktop@Exec=/opt/Signal/signal-desktop --no-sandbox@' "$DESKTOP_FILE"

    log "Step 2: Categorizing Start Menu entry..."
    sed -i 's/Categories=.*/Categories=Network;InstantMessaging;Chat;/g' "$DESKTOP_FILE"

    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    log "Step 3: Deploying Desktop shortcut to $KASM_HOME"
    mkdir -p "$KASM_HOME/Desktop"
    cp "$DESKTOP_FILE" "$KASM_HOME/Desktop/signal-desktop.desktop"
    chmod +x "$KASM_HOME/Desktop/signal-desktop.desktop"
    chown 1000:1000 "$KASM_HOME/Desktop/signal-desktop.desktop"

    # Step 4: Disable Autostart at Session Login
    log "Step 4: Disabling auto-start at login to preserve Kasm resources..."
    AUTOSTART_DIR="$KASM_HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"

    cat <<EOF > "$AUTOSTART_DIR/signal-desktop.desktop"
[Desktop Entry]
Type=Application
Name=Signal
Exec=/opt/Signal/signal-desktop --no-sandbox
X-GNOME-Autostart-enabled=false
NoDisplay=true
EOF

    # Ensure permissions are correct for the Kasm user
    chown -R 1000:1000 "$KASM_HOME/.config"

    log "Signal UI configuration complete."
else
    log "WARNING: signal-desktop.desktop not found at $DESKTOP_FILE."
fi
