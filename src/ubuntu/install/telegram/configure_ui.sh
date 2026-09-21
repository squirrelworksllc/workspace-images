#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Single menu entry, autostart suppression, opt-in Desktop icon.
# Optimized for: Kasm 1.18+ / Ubuntu Noble
###############################################################################
set -euo pipefail

log() { echo "[TELEGRAM-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

# --- Step 0: De-duplicate the packaged menu entries ---
log "Cleaning up duplicate menu entries..."
rm -f /usr/share/applications/telegram-desktop.desktop
rm -f /usr/share/applications/org.telegram.desktop.desktop

# 1. Determine Binary Path
if [ -f "/opt/Telegram/Telegram" ]; then
    EXEC_PATH="/opt/Telegram/Telegram"
    ICON_PATH="/opt/Telegram/telegram_icon.png"
    if [ ! -f "$ICON_PATH" ]; then
        log "Downloading Telegram icon..."
        curl -fsSL https://kasm-static-content.s3.amazonaws.com/icons/telegram.png -o "$ICON_PATH"
    fi
elif [ -f "/usr/bin/telegram-desktop" ]; then
    EXEC_PATH="/usr/bin/telegram-desktop"
    ICON_PATH="telegram" 
else
    log "ERROR: Telegram binary not found. UI configuration aborted."
    exit 1
fi

log "Writing single source-of-truth: /usr/share/applications/telegram.desktop"
# No -workdir: Telegram defaults to ~/.local/share/TelegramDesktop at runtime.
# Baking $KASM_HOME here would pin it to the build-time home.
cat >/usr/share/applications/telegram.desktop <<EOL
[Desktop Entry]
Version=1.0
Name=Telegram Desktop
Comment=Official desktop version of Telegram messaging app
Exec=$EXEC_PATH -- %u
Icon=$ICON_PATH
Terminal=false
StartupWMClass=TelegramDesktop
Type=Application
Categories=Network;Chat;InstantMessaging;Qt;
MimeType=x-scheme-handler/tg;
Keywords=tg;chat;im;messaging;messenger;sms;tdesktop;
X-GNOME-UsesNotifications=true
EOL

chmod +x /usr/share/applications/telegram.desktop

# 2. Start Menu Refresh
if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

# 3. FIX: Disable Autostart (Nuclear Style)
log "Step 3: Disabling auto-start at login..."
rm -f /etc/xdg/autostart/telegramdesktop.desktop

AUTOSTART_DIR="$KASM_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat <<EOF > "$AUTOSTART_DIR/telegramdesktop.desktop"
[Desktop Entry]
Type=Application
Name=Telegram Desktop
Exec=$EXEC_PATH -startintray
X-GNOME-Autostart-enabled=false
Hidden=true
NoDisplay=true
EOF

# Ensure the Kasm user owns their config/local directories
# (Noble runs the session user with primary group 0)
mkdir -p "$KASM_HOME/.local/share/TelegramDesktop"
chown -R 1000:0 "$KASM_HOME/.config" "$KASM_HOME/.local" 2>/dev/null || true

# Desktop icon (opt-in via TELEGRAM_DESKTOP_ICON=true; default off)
desktop_icon telegram /usr/share/applications/telegram.desktop false

log "Telegram UI configuration complete."
