#!/usr/bin/env bash
###############################################################################
# install_filezilla.sh
# Purpose: Installs FileZilla for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[FILEZILLA-INSTALL] $*"; }

main() {
    log "======= Installing FileZilla ======="

    apt_update_if_needed
    apt_install filezilla

    log "Triggering UI and Configuration integration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "FileZilla installation complete."
}

main "$@"
