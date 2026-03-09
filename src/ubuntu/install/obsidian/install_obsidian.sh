#!/usr/bin/env bash
###############################################################################
# install_obsidian.sh
# Purpose: Installs Obsidian via official .deb for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[OBSIDIAN-INSTALL] $*"; }

main() {
    log "======= Installing Obsidian ======="

    ARCH="$(dpkg --print-architecture)"
    # Map dpkg arch to Obsidian naming (usually amd64 or arm64)
    apt_update_if_needed
    apt_install curl jq

    log "Step 1: Finding latest .deb release..."
    RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest)"
    
    # Filter for the .deb asset matching our architecture
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r ".assets[] | select(.name | endswith(\".deb\")) | select(.name | contains(\"${ARCH}\")) | .browser_download_url" | head -n1)

    if [ -z "${DOWNLOAD_URL}" ] || [ "${DOWNLOAD_URL}" = "null" ]; then
        log "ERROR: Could not find .deb for ${ARCH}" >&2
        exit 1
    fi

    log "Step 2: Downloading and Installing..."
    curl -fsSL "$DOWNLOAD_URL" -o /tmp/obsidian.deb
    
    # Using apt to install the local deb handles all electron/library dependencies
    apt-get install -y /tmp/obsidian.deb
    rm -f /tmp/obsidian.deb

    log "Step 3: Triggering UI and environment configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Obsidian installation complete."
}

main "$@"
