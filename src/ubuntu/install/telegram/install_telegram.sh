#!/usr/bin/env bash
# This script installs Telegram. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Telegram ======="

ARCH="$(dpkg --print-architecture)"
. /etc/os-release

mkdir -p "$HOME/Desktop"

if [ "${ARCH}" = "arm64" ]; then
  # Telegram Desktop deb may be missing on some new suites for arm64
  if [ "${VERSION_CODENAME:-}" = "noble" ] || [ "${VERSION_CODENAME:-}" = "trixie" ]; then
    echo "Telegram not available for ${VERSION_CODENAME} on arm64; skipping."
    exit 0
  fi

  apt_update_if_needed
  apt_install telegram-desktop

  # Desktop file name differs by distro/package
  if [ -f /usr/share/applications/org.telegram.desktop.desktop ]; then
    cp /usr/share/applications/org.telegram.desktop.desktop "$HOME/Desktop/telegram.desktop"
  elif [ -f /usr/share/applications/telegramdesktop.desktop ]; then
    cp /usr/share/applications/telegramdesktop.desktop "$HOME/Desktop/telegram.desktop"
  else
    echo "Could not find Telegram desktop entry to copy." >&2
  fi

  chmod +x "$HOME/Desktop/telegram.desktop" 2>/dev/null || true
  chown 1000:1000 "$HOME/Desktop/telegram.desktop" 2>/dev/null || true

else
  # Use official Telegram tarball
  curl -fsSL https://telegram.org/dl/desktop/linux -o /tmp/telegram.tgz
  tar -xf /tmp/telegram.tgz -C /opt/
  rm -f /tmp/telegram.tgz

  curl -fsSL https://kasm-static-content.s3.amazonaws.com/icons/telegram.png -o /opt/Telegram/telegram_icon.png

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

  chmod +x /usr/share/applications/telegram.desktop
  cp /usr/share/applications/telegram.desktop "$HOME/Desktop/telegram.desktop"
  chmod +x "$HOME/Desktop/telegram.desktop" 2>/dev/null || true
  chown 1000:1000 "$HOME/Desktop/telegram.desktop" 2>/dev/null || true
fi

echo "Telegram install complete."