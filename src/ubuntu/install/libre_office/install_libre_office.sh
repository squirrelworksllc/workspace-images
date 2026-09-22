#!/usr/bin/env bash
###############################################################################
# install_libre_office.sh
# Purpose: Installs LibreOffice for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
LOG_TAG="LIBREOFFICE-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing LibreOffice ======="

    apt_update_if_needed

    # Core suite + GTK3 integration. apt_install already passes
    # --no-install-recommends, keeping the fonts/language bloat out.
    apt_install libreoffice-calc libreoffice-draw libreoffice-impress \
                libreoffice-writer libreoffice-gtk3 libreoffice-common

    run_configure_ui
    log "LibreOffice installation complete."
}

main "$@"
