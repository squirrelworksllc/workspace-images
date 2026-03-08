#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Configures UI elements and shortcuts for telegram.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail

log() { echo "[telegram-ui] $*"; }

log "Downloading Telegram icon"
curl -fsSL https://kasm-static-content.s3.amazonaws.com/icons/telegram.png -o /opt/Telegram/telegram_icon.png

log "Writing desktop entry to /usr/share/applications/telegram.desktop"
cat >/usr/share/applications/telegram.desktop <<'EOL'
[Desktop Entry]
Version=1.0
Name=Telegram Desktop
Comment=Official desktop version of Telegram messaging app
TryExec=/opt/Telegram/Telegram
Exec=/opt/Telegram/Telegram -- %u
Icon=/opt/Telegram/telegram_icon.png
Terminal=false
StartupWMClass=TelegramDesktop
Type=Application
Categories=Chat;Network;InstantMessaging;Qt;
MimeType=x-scheme-handler/tg;
Keywords=tg;chat;im;messaging;messenger;sms;tdesktop;
X-GNOME-UsesNotifications=true
EOL

log "Creating desktop shortcut"
chmod +x /usr/share/applications/telegram.desktop
desktop_dir="${HOME}/Desktop"
mkdir -p "${desktop_dir}"

if [ -f /usr/share/applications/org.telegram.desktop.desktop ]; then
  cp /usr/share/applications/org.telegram.desktop.desktop "${desktop_dir}/telegram.desktop"
elif [ -f /usr/share/applications/telegramdesktop.desktop ]; then
  cp /usr/share/applications/telegramdesktop.desktop "${desktop_dir}/telegram.desktop"
elif [ -f /usr/share/applications/telegram.desktop ]; then
  cp /usr/share/applications/telegram.desktop "${desktop_dir}/telegram.desktop"
else
  log "WARNING: could not find Telegram desktop entry to copy." >&2
fi

if [ -f "${desktop_dir}/telegram.desktop" ]; then
  chmod +x "${desktop_dir}/telegram.desktop" 2>/dev/null || true
  chown 1000:1000 "${desktop_dir}/telegram.desktop" 2>/dev/null || true
fi
