#!/usr/bin/env bash
###############################################################################
# install_google_chrome.sh
# Purpose: Installs Google Chrome with Advanced Wrappers & Desktop Shortcut
###############################################################################
set -euo pipefail

# Kasm-specific paths
: "${INST_DIR:=/dockerstartup/install}"
# Source apt helper for SquirrelWorks standard updates
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[CHROME-INSTALL] $*"; }

main() {
    log "======= Installing Google Chrome Stable ======="

    ARCH="$(dpkg --print-architecture)"
    if [ "${ARCH}" = "arm64" ]; then
        log "Chrome not supported on arm64, skipping."
        exit 0
    fi

    apt_update_if_needed
    apt_install wget ca-certificates

    CHROME_VERSION="${1:-}"
    if [ -n "${CHROME_VERSION}" ]; then
        log "Downloading pinned version: ${CHROME_VERSION}"
        wget -q "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb" -O /tmp/chrome.deb
    else
        log "Downloading latest current version..."
        wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O /tmp/chrome.deb
    fi

    # Install the deb and handle dependencies automatically
    apt-get install -y /tmp/chrome.deb
    rm -f /tmp/chrome.deb

    # Desktop icon + binary wrapper + policies are all handled by configure_ui.sh
    log "Triggering advanced UI and Policy configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Google Chrome installation complete."
}

main "$@"
