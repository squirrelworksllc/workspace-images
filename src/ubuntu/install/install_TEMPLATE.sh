#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# install_APPNAME.sh
#
# Debian-based only (Debian / Ubuntu).
# Intended to be called non-interactively from a Dockerfile to install
# [APP NAME] into a Kasm-enabled Ubuntu image.
#
# Responsibilities:
#   - Install [APP NAME] via apt or external tarball/binary
#   - Create desktop entry in /usr/share/applications
#   - Place a launcher on the user's Desktop and set ownership to uid 1000 / gid 0
#     (Kasm Noble runs the session user with primary group 0)
#
# Env expectations:
#   INST_DIR   (default: /dockerstartup/install) - location of apt helper
###############################################################################

: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[APPNAME] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[APPNAME] ERROR: must be run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  # Fail early with a clear message if helper functions aren't present
  command -v apt_install >/dev/null 2>&1 || {
    echo "[APPNAME] ERROR: apt_install not defined (apt helper not sourced?)" >&2
    exit 1
  }
  command -v apt_update_if_needed >/dev/null 2>&1 || {
    echo "[APPNAME] ERROR: apt_update_if_needed not defined (apt helper not sourced?)" >&2
    exit 1
  }

  echo "======= Installing APPNAME ======="

  # Step 1: Detect architecture if needed
  local arch
  arch="$(dpkg --print-architecture)"
  log "Detected architecture: ${arch}"

  # Step 2: Install packages
  log "Step 2: Installing packages"
  apt_update_if_needed
  # apt_install package1 package2

  # Step 3: Desktop shortcut
  log "Step 3: Setting up desktop shortcut"
  # Resolve the primary user's home from the passwd DB, not $HOME.
  local kasm_home
  kasm_home="$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")"

  # if [ -f "/usr/share/applications/APPNAME.desktop" ]; then
  #   mkdir -p "${kasm_home}/Desktop"
  #   cp "/usr/share/applications/APPNAME.desktop" "${kasm_home}/Desktop/APPNAME.desktop"
  #   chmod +x "${kasm_home}/Desktop/APPNAME.desktop" 2>/dev/null || true
  #   chown -R 1000:0 "${kasm_home}/Desktop" 2>/dev/null || true
  # else
  #   log "WARNING: APPNAME.desktop not found."
  # fi

  log "APPNAME install complete."
}

main "$@"