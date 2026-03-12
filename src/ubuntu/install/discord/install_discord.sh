#!/usr/bin/env bash
###############################################################################
# install_discord.sh
# Purpose: Installs Discord for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[DISCORD-INSTALL] $*"; }

main() {
    log "======= Installing Discord ======="

    apt_update_if_needed
    apt_install libnss3 libasound2t64 libatk-bridge2.0-0

    log "Step 1: Downloading latest Discord DEB..."
    # Discord always redirects this URL to the newest stable version
    curl -fsSL -o /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"

    log "Step 2: Installing package..."
    apt-get install -y /tmp/discord.deb
    rm -f /tmp/discord.deb

    log "Step 3: Triggering UI configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Discord installation complete."
}

main "$@"
