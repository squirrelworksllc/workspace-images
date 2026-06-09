#!/usr/bin/env bash
###############################################################################
# install_origamindee.sh
# Purpose: Installs Origamindee (Ruby PDF library) into the Ubuntu workspace.
#          Project documentation: https://github.com/mindee/origamindee
# Note: pdfwalker is explicitly excluded due to GTK2/Ruby 3.2 incompatibility.
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

    # 3. Pull the gem globally (CLI tools: pdfcop, pdfdecompress)
    log "Installing origamindee gem..."
    gem install origamindee

    log "Origamindee CLI tools installed successfully."
}

main "$@"
