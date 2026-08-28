#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements, sandboxing, and prevents Signal autostart.
# Architecture: SquirrelWorks 1.1 - Clean Desktop & Nuclear Autostart
###############################################################################
set -euo pipefail

log() { echo "[SIGNAL-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

DESKTOP_FILE="/usr/share/applications/signal-desktop.desktop"
SYSTEM_AUTOSTART="/etc/xdg/autostart/signal-desktop.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    log "Step 1: Applying --no-sandbox fix for Kasm compatibility..."
    # Mandatory for Signal (Electron) in most Kasm/Docker environments (idempotent)
    if ! grep -q -- '--no-sandbox' "$DESKTOP_FILE"; then
        sed -i 's@Exec=/opt/Signal/signal-desktop@Exec=/opt/Signal/signal-desktop --no-sandbox@' "$DESKTOP_FILE"
    fi

    log "Step 2: Categorizing Start Menu entry..."
    sed -i 's/Categories=.*/Categories=Network;InstantMessaging;Chat;/g' "$DESKTOP_FILE"

    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    # Step 4: Nuclear Option - Remove System Autostart
    if [ -f "$SYSTEM_AUTOSTART" ]; then
        log "Step 4: Nuclear Strike - Removing $SYSTEM_AUTOSTART..."
        rm -f "$SYSTEM_AUTOSTART"
    else
        log "Step 4: No system autostart found. Skipping removal."
    fi

    # Step 5: Pre-emptive Profile Block
    log "Step 5: Masking autostart in kasm-default-profile..."
    AUTOSTART_DIR="$KASM_HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"

    # Using 'Hidden=true' to ensure the desktop manager ignores this entry
    cat <<EOF > "$AUTOSTART_DIR/signal-desktop.desktop"
[Desktop Entry]
Type=Application
Name=Signal
Exec=/opt/Signal/signal-desktop --no-sandbox
X-GNOME-Autostart-enabled=false
Hidden=true
NoDisplay=true
EOF

    # Ensure permissions are correct for the Kasm default profile (UID 1000, group 0)
    chown -R 1000:0 "$KASM_HOME/.config" 2>/dev/null || true

    log "Signal UI configuration (Nuclear/Clean-Desktop) complete."
else
    log "WARNING: signal-desktop.desktop not found at $DESKTOP_FILE."
fi

# Desktop icon (opt-in via SIGNAL_DESKTOP_ICON=true; default off)
desktop_icon signal "$DESKTOP_FILE" false
