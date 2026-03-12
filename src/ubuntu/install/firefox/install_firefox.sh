#!/usr/bin/env bash
###############################################################################
# install_firefox.sh
# Purpose: Installs Firefox via Mozilla APT (Non-Snap) for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[FIREFOX-INSTALL] $*"; }

main() {
    log "======= Installing Firefox (Mozilla Repo) ======="

    . /etc/os-release
    apt_update_if_needed

    log "Step 1: Configuring Mozilla APT Repository..."
    install -m 0755 -d /etc/apt/keyrings
    wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/mozilla.gpg
    
    echo "deb [signed-by=/etc/apt/keyrings/mozilla.gpg] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.firefox.list

    # Prioritize Mozilla repo over Ubuntu's empty snap-wrapper
    cat > /etc/apt/preferences.d/mozilla-firefox <<EOF
Package: firefox*
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

    apt_refresh_after_repo_change
    apt_install firefox

    log "Step 2: Triggering Hardening and UI configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Firefox installation complete."
}

main "$@"
