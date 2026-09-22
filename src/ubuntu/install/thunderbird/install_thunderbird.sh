#!/usr/bin/env bash
###############################################################################
# install_thunderbird.sh
# Purpose: Installs Thunderbird from the Mozilla Team PPA (never the snap).
###############################################################################
set -euo pipefail
LOG_TAG="THUNDERBIRD-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Thunderbird (DEB, no snap) ======="

    . /etc/os-release
    apt_update_if_needed

    case "${ID}" in
        ubuntu)
            log "Ubuntu: prepping the PPA and blocking the snap..."
            command -v snap >/dev/null 2>&1 && snap remove --purge thunderbird 2>/dev/null || true
            apt-get remove -y thunderbird || true

            add-apt-repository -y ppa:mozillateam/ppa

            # Pin the PPA above the snap transitional package (do this first).
            cat >/etc/apt/preferences.d/thunderbird <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: thunderbird
Pin: version 2:1snap*
Pin-Priority: -1
EOF
            apt_refresh_after_repo_change
            apt_install thunderbird
            ;;
        debian|kali)
            apt_install thunderbird
            ;;
        *)
            log "ERROR: Unsupported distro: ${ID}" >&2
            exit 1
            ;;
    esac

    run_configure_ui
    log "Thunderbird installation complete!"
}

main "$@"
