#!/usr/bin/env bash
###############################################################################
# install_origamindee.sh
# Purpose: Installs Origamindee (Ruby PDF library) into the Ubuntu workspace.
#          Project documentation: https://github.com/mindee/origamindee
# Note: pdfwalker is explicitly excluded due to GTK2/Ruby 3.2 incompatibility.
###############################################################################
set -euo pipefail
LOG_TAG="ORIGAMINDEE-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Origamindee (Ruby PDF Library) ======="

    apt_update_if_needed
    apt_install ruby-full build-essential

    # Global gem -> CLI tools pdfcop, pdfdecompress.
    gem install origamindee

    log "Origamindee CLI tools installed successfully."
}

main "$@"
