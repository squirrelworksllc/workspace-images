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
#   - Place a launcher on the user's Desktop and set ownership to uid/gid 1000
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
  local desktop_dir="${HOME}/Desktop"
  mkdir -p "${desktop_dir}"

  # if [ -f "/usr/share/applications/APPNAME.desktop" ]; then
  #   cp "/usr/share/applications/APPNAME.desktop" "${desktop_dir}/APPNAME.desktop"
  #   chmod +x "${desktop_dir}/APPNAME.desktop" 2>/dev/null || true
  #   chown 1000:1000 "${desktop_dir}/APPNAME.desktop" 2>/dev/null || true
  # else
  #   log "WARNING: APPNAME.desktop not found."
  # fi

  log "APPNAME install complete."
}

main "$@"