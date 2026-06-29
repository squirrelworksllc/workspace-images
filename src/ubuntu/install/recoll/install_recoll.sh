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
    log "Ubuntu detected."
    # ARCHITECT NOTE: Ubuntu 24.04 (Noble) natively hosts Recoll 1.37+ in the universe repository.
  fi

  # Install core indexing engine, GUI, CLI tooling, and Python bindings
  apt_install recoll recollgui recollcmd python3-recoll

  log "Triggering UI and Environment configuration..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
  fi

  log "Recoll installation complete."
}

main "$@"
