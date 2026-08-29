#!/usr/bin/env bash
###############################################################################
# install_edge.sh
# Purpose: Installs Microsoft Edge Stable via the Microsoft production repo.
###############################################################################
set -euo pipefail
LOG_TAG="EDGE-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Microsoft Edge Stable ======="

    apt_update_if_needed
    . /etc/os-release

    local cfg
    case "${ID}" in
        ubuntu)
            cfg="https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"
            ;;
        debian|kali)
            local major="${VERSION_ID:-12}"
            major="${major%%.*}"
            cfg="https://packages.microsoft.com/config/debian/${major}/packages-microsoft-prod.deb"
            ;;
        *)
            log "ERROR: Unsupported distro: ${ID}" >&2
            exit 1
            ;;
    esac

    log "Installing the Microsoft repo config package..."
    install_deb "$cfg"
    apt_refresh_after_repo_change
    apt_install microsoft-edge-stable

    run_configure_ui
    log "Edge installation complete."
}

main "$@"
