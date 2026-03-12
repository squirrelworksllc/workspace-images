#!/usr/bin/env bash
###############################################################################
# install_telegram.sh
#
# Purpose: Installs Telegram (Apt for ARM64, Tarball for AMD64)
###############################################################################
set -euo pipefail
IFS=$'\n\t'

: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[telegram-install] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "ERROR: must be run as root" >&2
    exit 1
  fi
}

install_via_apt_arm64() {
  local arch
  arch="$(dpkg --print-architecture)"
  if [ "${arch}" != "arm64" ]; then return 1; fi

  . /etc/os-release
  if [ "${VERSION_CODENAME:-}" = "noble" ] || [ "${VERSION_CODENAME:-}" = "trixie" ]; then
    log "Telegram not available in apt for ${VERSION_CODENAME} on arm64; skipping."
    exit 0
  fi

  log "Step 1: Installing telegram-desktop from apt (arm64)"
  apt_update_if_needed
  apt_install telegram-desktop

  log "Step 2: Configuring UI elements"
  # Use SCRIPT_DIR to find the UI script relative to this one
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "${SCRIPT_DIR}/configure_ui.sh"
}

install_via_tarball() {
  log "Step 1: Downloading Telegram tarball (AMD64)"
  curl -fsSL https://telegram.org/dl/desktop/linux -o /tmp/telegram.tgz
  
  log "Step 2: Extracting Telegram into /opt"
  rm -rf /opt/Telegram
  tar -xf /tmp/telegram.tgz -C /opt/
  rm -f /tmp/telegram.tgz

  # Create symlink so 'telegram' works in CLI
  ln -sf /opt/Telegram/Telegram /usr/local/bin/telegram

  log "Step 3: Configuring UI elements"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "${SCRIPT_DIR}/configure_ui.sh"
}

main() {
  require_root
  log "======= Installing Telegram ======="

  local arch
  arch="$(dpkg --print-architecture)"

  if [ "${arch}" = "arm64" ]; then
    install_via_apt_arm64
  else
    install_via_tarball
  fi

  log "Telegram install complete."
}

main "$@"
