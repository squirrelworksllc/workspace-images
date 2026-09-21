#!/usr/bin/env bash
###############################################################################
# install_vlc.sh
# Purpose: Installs VLC and triggers UI integration.
###############################################################################
set -euo pipefail
LOG_TAG="VLC-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing VLC Media Player ======="

    apt_update_if_needed
    apt_install vlc

    run_configure_ui
    log "VLC installation complete!"
}

main "$@"
