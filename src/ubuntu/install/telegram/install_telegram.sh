#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# install_telegram.sh
#
# Debian-based only (Debian / Ubuntu).
# Intended to be called non-interactively from a Dockerfile to install
# Telegram Desktop into a Kasm-enabled Ubuntu image.
#
# Responsibilities:
#   - Install Telegram Desktop (apt for arm64 where available, tarball otherwise)
#   - Create desktop entry in /usr/share/applications
#   - Place a launcher on the user's Desktop and set ownership to uid/gid 1000
#
# Env expectations:
#   INST_DIR   (default: /dockerstartup/install) - location of apt helper
###############################################################################

# Align with other installers (torsocks, Slack, etc.)
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[telegram] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[telegram] ERROR: must be run as root" >&2
    exit 1
  fi
}

install_via_apt_arm64() {
  # Step 1: Detect architecture and suite; Telegram Desktop deb may be
  # missing on some new suites for arm64.
  local arch
  arch="$(dpkg --print-architecture)"

  if [ "${arch}" != "arm64" ]; then
    return 1
  fi

  # Step 2: Load distro information for suite checks.
  # shellcheck source=/dev/null
  . /etc/os-release

  if [ "${VERSION_CODENAME:-}" = "noble" ] || [ "${VERSION_CODENAME:-}" = "trixie" ]; then
    log "Telegram not available for ${VERSION_CODENAME} on arm64; skipping install."
    exit 0
  fi

  # Step 3: Fail early with a clear message if helper functions aren't present.
  command -v apt_install >/dev/null 2>&1 || {
    echo "[telegram] ERROR: apt_install not defined (apt helper not sourced?)" >&2
    exit 1
  }
  command -v apt_update_if_needed >/dev/null 2>&1 || {
    echo "[telegram] ERROR: apt_update_if_needed not defined (apt helper not sourced?)" >&2
    exit 1
  }

  log "Step 4: Installing telegram-desktop from apt (arm64)"
  apt_update_if_needed
  apt_install telegram-desktop

  local desktop_dir="${HOME}/Desktop"
  mkdir -p "${desktop_dir}"

  log "Step 5: Creating desktop shortcut from system .desktop entry"
  # Desktop file name differs by distro/package.
  if [ -f /usr/share/applications/org.telegram.desktop.desktop ]; then
    cp /usr/share/applications/org.telegram.desktop.desktop "${desktop_dir}/telegram.desktop"
  elif [ -f /usr/share/applications/telegramdesktop.desktop ]; then
    cp /usr/share/applications/telegramdesktop.desktop "${desktop_dir}/telegram.desktop"
  else
    echo "[telegram] WARNING: could not find Telegram desktop entry to copy." >&2
  fi

  chmod +x "${desktop_dir}/telegram.desktop" 2>/dev/null || true
  chown 1000:1000 "${desktop_dir}/telegram.desktop" 2>/dev/null || true

  return 0
}

install_via_tarball() {
  # Use official Telegram tarball for non-arm64 architectures.
  log "Step 1: Downloading Telegram tarball"

  curl -fsSL https://telegram.org/dl/desktop/linux -o /tmp/telegram.tgz
  log "Step 2: Extracting Telegram into /opt"
  tar -xf /tmp/telegram.tgz -C /opt/
  rm -f /tmp/telegram.tgz

  log "Step 3: Downloading Telegram icon"
  curl -fsSL https://kasm-static-content.s3.amazonaws.com/icons/telegram.png -o /opt/Telegram/telegram_icon.png

  log "Step 4: Writing desktop entry to /usr/share/applications/telegram.desktop"
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

  log "Step 5: Creating desktop shortcut"
  chmod +x /usr/share/applications/telegram.desktop

  local desktop_dir="${HOME}/Desktop"
  mkdir -p "${desktop_dir}"

  cp /usr/share/applications/telegram.desktop "${desktop_dir}/telegram.desktop"
  chmod +x "${desktop_dir}/telegram.desktop" 2>/dev/null || true
  chown 1000:1000 "${desktop_dir}/telegram.desktop" 2>/dev/null || true
}

main() {
  require_root

  echo "======= Installing Telegram ======="

  local arch
  arch="$(dpkg --print-architecture)"

  if [ "${arch}" = "arm64" ]; then
    echo "Detected architecture: arm64 -> using apt package if available"
    install_via_apt_arm64
  else
    echo "Detected architecture: ${arch} -> using official Telegram tarball"
    install_via_tarball
  fi

  echo "Telegram install complete."
}

main "$@"
