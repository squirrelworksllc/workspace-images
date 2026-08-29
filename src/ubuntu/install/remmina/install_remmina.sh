#!/usr/bin/env bash
###############################################################################
# install_remmina.sh
# Purpose: Installs Remmina + RDP, VNC, and SPICE for Kasm 1.18+
###############################################################################
set -euo pipefail
LOG_TAG="REMMINA-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

REMMINA_PKGS=(remmina remmina-plugin-rdp remmina-plugin-vnc
              remmina-plugin-spice remmina-plugin-secret xdotool)

main() {
    log "======= Installing Remmina (Full Plugin Suite) ======="

    . /etc/os-release
    apt_update_if_needed

    case "${ID}" in
        ubuntu)
            if [ "${VERSION_CODENAME:-}" != "noble" ]; then
                log "Legacy Ubuntu - adding the remmina-next PPA..."
                add-apt-repository -y ppa:remmina-ppa-team/remmina-next
                apt_refresh_after_repo_change
            fi
            apt_install "${REMMINA_PKGS[@]}"
            ;;
        debian|kali)
            apt_install "${REMMINA_PKGS[@]}"
            ;;
        *)
            log "ERROR: Unsupported distro: ${ID}" >&2
            exit 1
            ;;
    esac

    run_configure_ui
    log "Remmina installation complete!"
}

main "$@"
