#!/usr/bin/env bash
###############################################################################
# install_recoll.sh
# Purpose: Installs Recoll for SquirrelWorks 1.1 (Noble/Debian)
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[RECOLL-INSTALL] $*"; }

main() {
  log "======= Installing Recoll Full-Text Search ======="

  . /etc/os-release
  apt_update_if_needed

  if [ "${ID}" = "ubuntu" ]; then
    log "Ubuntu detected - Adding Recoll PPA for modern indexing..."
    # We use the 'recoll-1.15-on' PPA which is the standard for modern Ubuntu
    add-apt-repository -y ppa:recoll-backports/recoll-1.15-on
    apt_refresh_after_repo_change
  fi

  # core: recoll, GUI: recollgui, CLI: recollcmd
  # We also add 'python3-recoll' for potential automation scripts
  apt_install recoll recollgui recollcmd python3-recoll

  log "Triggering UI and Environment configuration..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
  fi

  log "Recoll installation complete."
}

main "$@"
