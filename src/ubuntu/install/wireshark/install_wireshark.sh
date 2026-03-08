#!/usr/bin/env bash
set -euo pipefail
IFS=$'
	'

###############################################################################
# install_wireshark.sh
#
# Debian-based only (Debian / Ubuntu).
# Intended to be called non-interactively from a Dockerfile to install
# Wireshark into a Kasm-enabled Ubuntu image.
#
# Responsibilities:
#   - Add the official wireshark-dev PPA
#   - Install Wireshark and tshark with a robust retry mechanism to bypass
#     flaky Launchpad connections.
#   - Place a launcher on the user's Desktop and set ownership.
#
# Env expectations:
#   INST_DIR   (default: /dockerstartup/install) - location of apt helper
###############################################################################

: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[wireshark] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[wireshark] ERROR: must be run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  # Fail early with a clear message if helper functions aren't present
  command -v apt_install >/dev/null 2>&1 || {
    echo "[wireshark] ERROR: apt_install not defined (apt helper not sourced?)" >&2
    exit 1
  }
  command -v apt_update_if_needed >/dev/null 2>&1 || {
    echo "[wireshark] ERROR: apt_update_if_needed not defined (apt helper not sourced?)" >&2
    exit 1
  }

  echo "======= Installing Wireshark ======="

  log "Step 1: Installing prerequisites for PPA"
  apt_update_if_needed
  apt_install software-properties-common

  log "Step 2: Adding Wireshark Dev PPA"
  # Default to false for install-setuid prompt (REMnux handles its own groups later)
  echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections
  
  # Attempt to add the PPA
  add-apt-repository -y ppa:wireshark-dev/stable

  log "Step 3: Installing Wireshark with retries"
  apt_update_if_needed
  
  # Launchpad PPAs can drop connections intermittently. We wrap the installation in a loop.
  local max_retries=5
  local attempt=1
  local success=false

  while [ "$attempt" -le "$max_retries" ]; do
    log "Install attempt $attempt of $max_retries..."
    if apt_install wireshark tshark; then
      success=true
      break
    else
      log "Attempt $attempt failed. Waiting 10 seconds before retrying..."
      sleep 10
      # Clean out bad lists/partials and update again
      apt-get clean -y
      apt_get update -o Acquire::Retries=3
      attempt=$((attempt + 1))
    fi
  done

  if [ "$success" = false ]; then
    echo "[wireshark] ERROR: Failed to install Wireshark after $max_retries attempts." >&2
    exit 1
  fi

  log "Step 4: Setting up desktop shortcut"
  local desktop_dir="${HOME}/Desktop"
  mkdir -p "${desktop_dir}"

  if [ -f /usr/share/applications/wireshark.desktop ]; then
    cp /usr/share/applications/wireshark.desktop "${desktop_dir}/wireshark.desktop"
    chmod +x "${desktop_dir}/wireshark.desktop" 2>/dev/null || true
    chown 1000:1000 "${desktop_dir}/wireshark.desktop" 2>/dev/null || true
  else
    log "WARNING: wireshark.desktop not found in /usr/share/applications/"
  fi

  log "Wireshark install complete."
}

main "$@"
