#!/usr/bin/env bash
###############################################################################
# install_chrome.sh
# Purpose: Installs Google Chrome Stable (.deb). The binary wrapper, managed
#          policies and the Desktop icon are handled by configure_ui.sh.
#
# Optional arg $1: a pinned version string (e.g. 128.0.6613.119-1).
###############################################################################
set -euo pipefail
LOG_TAG="CHROME-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Google Chrome Stable ======="
    require_arch amd64

    apt_update_if_needed
    apt_install ca-certificates

    local ver="${1:-}" url
    if [ -n "$ver" ]; then
        log "Pinned version: ${ver}"
        url="https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${ver}_amd64.deb"
    else
        url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    fi
    install_deb "$url"

    run_configure_ui
    log "Google Chrome installation complete."
}

main "$@"
