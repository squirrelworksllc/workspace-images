#!/usr/bin/env bash
###############################################################################
# install_origamindee.sh
# Purpose: Installs Origamindee (Ruby PDF library) into the Ubuntu workspace.
#          Project documentation: https://github.com/mindee/origamindee
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[ORIGAMINDEE-INSTALL] $*"; }

main() {
    log "======= Installing Origamindee (Ruby PDF Library) ======="

    # 1. Update the APT cache using our core helper
    apt_update_if_needed

    # 2. Install Ruby and essential build tools for native extensions
    log "Installing Ruby and build dependencies..."
    apt_install ruby-full build-essential

    # 3. Pull the gem globally
    log "Installing origamindee gem..."
    gem install origamindee

    # 4. Post-install configurations (Ephemerality/Persistence handling)
    log "Step 2: Triggering Advanced UI and Policy configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Origamindee installation complete."
}

main "$@"
