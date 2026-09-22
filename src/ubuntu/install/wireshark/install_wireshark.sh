#!/usr/bin/env bash
###############################################################################
# install_wireshark.sh
# Purpose: Installs Wireshark from the wireshark-dev PPA.
###############################################################################
set -euo pipefail
LOG_TAG="WIRESHARK-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    require_root
    log "======= Installing Wireshark ======="

    # Answer the "let non-root users capture?" debconf question up front.
    echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

    log "Adding the wireshark-dev PPA..."
    add-apt-repository -y ppa:wireshark-dev/stable
    apt_update_if_needed

    log "Installing wireshark + tshark (with retries)..."
    local attempt
    for attempt in 1 2 3; do
        if apt_install wireshark tshark; then
            run_configure_ui
            log "Wireshark installation complete!"
            return 0
        fi
        log "Attempt ${attempt} failed; retrying in 5s..."
        sleep 5
    done

    log "ERROR: Failed to install Wireshark after 3 attempts." >&2
    exit 1
}

main "$@"
