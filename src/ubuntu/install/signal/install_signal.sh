#!/usr/bin/env bash
###############################################################################
# install_signal.sh
# Purpose: Installs Signal Desktop from the official Signal apt repo.
###############################################################################
set -euo pipefail
LOG_TAG="SIGNAL-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Signal Desktop ======="
    require_arch amd64

    apt_update_if_needed
    add_apt_repo signal-desktop \
        "https://updates.signal.org/desktop/apt/keys.asc" \
        "https://updates.signal.org/desktop/apt" "xenial" "main"
    apt_install signal-desktop

    run_configure_ui
    log "Signal installation complete!"
}

main "$@"
