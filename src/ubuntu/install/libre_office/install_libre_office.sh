#!/usr/bin/env bash
###############################################################################
# install_libre_office.sh
# Purpose: Installs LibreOffice for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[LIBREOFFICE-INSTALL] $*"; }

main() {
    log "======= Installing LibreOffice ======="

    apt_update_if_needed
    
    # We install the core suite plus the GTK3 integration for better UI performance
    # --no-install-recommends prevents 500MB of unnecessary fonts/languages
    apt_install libreoffice-calc libreoffice-draw libreoffice-impress \
                libreoffice-writer libreoffice-gtk3 libreoffice-common

    log "Triggering UI configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "LibreOffice installation complete."
}

main "$@"
