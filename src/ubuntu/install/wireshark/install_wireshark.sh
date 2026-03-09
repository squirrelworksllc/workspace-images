#!/usr/bin/env bash
###############################################################################
# install_wireshark.sh
# Purpose: Installs Wireshark from PPA and triggers UI/Permission config.
###############################################################################
set -euo pipefail
IFS=$'\n\t'

: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[wireshark-install] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "ERROR: must be run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  log "======= Installing Wireshark ======="

  # Pre-seed debconf to avoid the interactive "Should non-superusers be able to capture packets?" prompt
  echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

  log "Step 1: Adding Wireshark Dev PPA..."
  add-apt-repository -y ppa:wireshark-dev/stable
  apt_update_if_needed

  log "Step 2: Installing Wireshark and Tshark..."
  # Retry logic for build stability
  local max_retries=3
  local attempt=1
  local success=false
  while [ "$attempt" -le "$max_retries" ]; do
    if apt_install wireshark tshark; then
      success=true; break
    else
      log "Attempt $attempt failed. Retrying..."
      sleep 5; attempt=$((attempt + 1))
    fi
  done

  if [ "$success" = false ]; then
    log "ERROR: Failed to install Wireshark." >&2
    exit 1
  fi

  log "Step 3: Triggering UI and Permission configuration..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
      bash "${SCRIPT_DIR}/configure_ui.sh"
  fi

  log "Wireshark installation complete!"
}

main "$@"
