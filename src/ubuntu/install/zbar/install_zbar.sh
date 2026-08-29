#!/usr/bin/env bash
###############################################################################
# install_zbar.sh
# Purpose: Installs ZBar packages and triggers relative UI configuration.
###############################################################################
set -euo pipefail
LOG_TAG="ZBAR-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing ZBar ======="

    apt_update_if_needed
    # zenity gives the no-webcam fallback a graphical file picker.
    apt_install zbar-tools libzbar-dev libv4l-0 zenity

    run_configure_ui
    log "ZBar installation complete."
}

main "$@"
