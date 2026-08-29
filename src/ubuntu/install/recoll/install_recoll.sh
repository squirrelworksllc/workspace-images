#!/usr/bin/env bash
###############################################################################
# install_recoll.sh
# Purpose: Installs Recoll for SquirrelWorks 1.1 (Noble/Debian)
###############################################################################
set -euo pipefail
LOG_TAG="RECOLL-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Recoll Full-Text Search ======="

    apt_update_if_needed

    # Ubuntu 24.04 (Noble) natively hosts Recoll 1.37+ in the universe repo -
    # indexing engine, GUI, CLI tooling, and the Python bindings.
    apt_install recoll recollgui recollcmd python3-recoll

    run_configure_ui
    log "Recoll installation complete."
}

main "$@"
