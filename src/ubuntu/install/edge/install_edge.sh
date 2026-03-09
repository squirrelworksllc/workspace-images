#!/usr/bin/env bash
###############################################################################
# install_edge.sh
# Purpose: Installs Microsoft Edge with Dynamic Repo Detection
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[EDGE-INSTALL] $*"; }

main() {
    log "======= Installing Microsoft Edge Stable ======="

    apt_update_if_needed
    apt_install curl ca-certificates gnupg

    . /etc/os-release
    
    # Identify the correct Microsoft Production repo for the OS
    case "${ID}" in
        ubuntu) MSCFG_URL="https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" ;;
        debian|kali) 
            DEB_MAJOR="${VERSION_ID:-12}"
            DEB_MAJOR="${DEB_MAJOR%%.*}"
            MSCFG_URL="https://packages.microsoft.com/config/debian/${DEB_MAJOR}/packages-microsoft-prod.deb" 
            ;;
        *) log "ERROR: Unsupported distro: ${ID}"; exit 1 ;;
    esac

    log "Step 1: Installing Microsoft Repository Config..."
    curl -fsSL -o /tmp/microsoft.deb "${MSCFG_URL}"
    dpkg -i /tmp/microsoft.deb
    rm -f /tmp/microsoft.deb

    apt_refresh_after_repo_change
    apt_install microsoft-edge-stable

    log "Step 2: Triggering Advanced UI and Policy configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Edge installation complete."
}

main "$@"
