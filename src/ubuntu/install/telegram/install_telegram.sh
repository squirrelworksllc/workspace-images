#!/usr/bin/env bash
###############################################################################
# install_telegram.sh
#
# Purpose: Installs telegram.
#
# Env expectations:
#   INST_DIR   (default: /dockerstartup/install) - location of apt helper
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail
IFS=$'\n\t'

# Align with other installers (torsocks, Slack, etc.)
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[telegram] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "[telegram] ERROR: must be run as root" >&2
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
    log "[telegram] ERROR: apt_install not defined (apt helper not sourced?)" >&2
    exit 1
  }
  command -v apt_update_if_needed >/dev/null 2>&1 || {
    log "[telegram] ERROR: apt_update_if_needed not defined (apt helper not sourced?)" >&2
    exit 1
  }

  log "Step 4: Installing telegram-desktop from apt (arm64)"
  apt_update_if_needed
  apt_install telegram-desktop

  local desktop_dir="${HOME}/Desktop"
  mkdir -p "${desktop_dir}"

  log "Step 5: Creating desktop shortcut from system .desktop entry"
  bash "${INST_DIR}/ubuntu/install/telegram/configure_ui.sh"

  return 0
}

install_via_tarball() {
  # Use official Telegram tarball for non-arm64 architectures.
  log "Step 1: Downloading Telegram tarball"

  curl -fsSL https://telegram.org/dl/desktop/linux -o /tmp/telegram.tgz
  log "Step 2: Extracting Telegram into /opt"
  tar -xf /tmp/telegram.tgz -C /opt/
  rm -f /tmp/telegram.tgz

  log "Step 2: Configuring UI elements and shortcuts"
  bash "${INST_DIR}/ubuntu/install/telegram/configure_ui.sh"
}

main() {
  require_root

  log "======= Installing Telegram ======="

  local arch
  arch="$(dpkg --print-architecture)"

  if [ "${arch}" = "arm64" ]; then
    log "Detected architecture: arm64 -> using apt package if available"
    install_via_apt_arm64
  else
    log "Detected architecture: ${arch} -> using official Telegram tarball"
    install_via_tarball
  fi

  log "Telegram install complete."
}

main "$@"
