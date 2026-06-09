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

    # Priority 1001 allows APT to cleanly overwrite Ubuntu's snap stub 
    cat > /etc/apt/preferences.d/mozilla-firefox <<EOF
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: origin packages.mozilla.org
Pin-Priority: 1001
EOF

    apt_refresh_after_repo_change
    
    log "Step 2: Installing and locking the Firefox package..."
    apt_install firefox
    
    # Lock the package so 02_remediation.sh ignores it during dist-upgrade
    apt-mark hold firefox

    log "Step 3: Triggering Hardening and UI configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Firefox installation complete."
}

main "$@"
