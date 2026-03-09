#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for telegram.
# Optimized for: Kasm 1.18+ / Ubuntu Noble
###############################################################################
set -euo pipefail

log() { echo "[TELEGRAM-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

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

log "Writing desktop entry to /usr/share/applications/telegram.desktop"
# We add -workdir so Telegram doesn't try to litter the root of the home dir
cat >/usr/share/applications/telegram.desktop <<EOL
[Desktop Entry]
Version=1.0
Name=Telegram Desktop
Comment=Official desktop version of Telegram messaging app
Exec=$EXEC_PATH -workdir $KASM_HOME/.local/share/TelegramDesktop -- %u
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

# 3. Kasm Desktop Shortcut
DESKTOP_DIR="$KASM_HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

log "Creating desktop shortcut..."
cp /usr/share/applications/telegram.desktop "$DESKTOP_DIR/telegram.desktop"
chmod +x "$DESKTOP_DIR/telegram.desktop"
chown 1000:1000 "$DESKTOP_DIR/telegram.desktop" 2>/dev/null || true

# 4. FIX: Disable Autostart
log "Step 4: Disabling auto-start at login..."
AUTOSTART_DIR="$KASM_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

# Note: Flush-left EOF is mandatory
cat <<EOF > "$AUTOSTART_DIR/telegramdesktop.desktop"
[Desktop Entry]
Type=Application
Name=Telegram Desktop
Exec=$EXEC_PATH -workdir $KASM_HOME/.local/share/TelegramDesktop -startintray
X-GNOME-Autostart-enabled=false
NoDisplay=true
EOF

chown -R 1000:1000 "$KASM_HOME/.config"
chown -R 1000:1000 "$KASM_HOME/.local"

log "Telegram UI configuration complete."
