#!/usr/bin/env bash
###############################################################################
# install_filezilla.sh
# Purpose: Installs FileZilla for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
LOG_TAG="FILEZILLA-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing FileZilla ======="

    apt_update_if_needed
    apt_install filezilla

    run_configure_ui
    log "FileZilla installation complete."
}

main "$@"
