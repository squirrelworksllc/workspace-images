#!/usr/bin/env bash
###############################################################################
# install_zbar.sh
# Purpose: Installs ZBar packages and triggers relative UI configuration.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[zbar-install] $*"; }

log "Starting ZBar backend installation..."

apt_update_if_needed
# zenity gives the no-webcam fallback a graphical file picker.
apt_install zbar-tools libzbar-dev libv4l-0 zenity

log "ZBar backend installation complete. Triggering UI configuration..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
else
    log "ERROR: configure_ui.sh not found in ${SCRIPT_DIR}!" >&2
    exit 1
fi

log "ZBar deployment pipeline finished successfully."
