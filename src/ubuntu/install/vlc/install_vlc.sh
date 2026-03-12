#!/usr/bin/env bash
###############################################################################
# install_vlc.sh
# Purpose: Installs VLC and triggers UI integration.
###############################################################################
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[VLC-INSTALL] $*"; }

log "======= Installing VLC Media Player ======="

log "Step 1: Installing VLC via apt..."
apt_update_if_needed
apt_install vlc

log "Step 2: Triggering UI and environment configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
fi

log "VLC installation complete!"
