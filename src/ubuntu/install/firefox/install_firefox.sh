#!/usr/bin/env bash
###############################################################################
# install_firefox.sh
# Purpose: Installs Firefox from the Mozilla apt repo (never the snap).
###############################################################################
set -euo pipefail
LOG_TAG="FIREFOX-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Firefox (Mozilla repo) ======="

    apt_update_if_needed
    add_apt_repo firefox \
        "https://packages.mozilla.org/apt/repo-signing-key.gpg" \
        "https://packages.mozilla.org/apt" "mozilla" "main"

    # Pin so the Mozilla build wins over Ubuntu's snap transitional package.
    cat > /etc/apt/preferences.d/mozilla-firefox <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: origin packages.mozilla.org
Pin-Priority: 1001
EOF

    apt_install firefox
    apt-mark hold firefox   # keep 02_remediation's dist-upgrade off it

    run_configure_ui
    log "Firefox installation complete."
}

main "$@"
