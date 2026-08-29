#!/usr/bin/env bash
###############################################################################
# install_discord.sh
# Purpose: Installs Discord for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
LOG_TAG="DISCORD-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Discord ======="

    apt_update_if_needed
    apt_install libnss3 libasound2t64 libatk-bridge2.0-0

    # discord.com/api/download redirects to the current stable .deb.
    install_deb "https://discord.com/api/download?platform=linux&format=deb"

    run_configure_ui
    log "Discord installation complete."
}

main "$@"
