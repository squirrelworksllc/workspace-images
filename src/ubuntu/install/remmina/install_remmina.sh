#!/usr/bin/env bash
###############################################################################
# install_remmina.sh
# Purpose: Installs Remmina + RDP, VNC, and SPICE for Kasm 1.18+
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[REMMINA-INSTALL] $*"; }

main() {
    log "======= Installing Remmina (Full Plugin Suite) ======="

    . /etc/os-release
    apt_update_if_needed

    case "${ID}" in
        ubuntu)
            if [ "${VERSION_CODENAME:-}" = "noble" ]; then
                log "Installing Noble native suite..."
                # Added VNC and SPICE for broader compatibility
                apt_install remmina remmina-plugin-rdp remmina-plugin-vnc \
                            remmina-plugin-spice remmina-plugin-secret xdotool
            else
                log "Applying PPA for legacy Ubuntu..."
                add-apt-repository -y ppa:remmina-ppa-team/remmina-next
                apt_refresh_after_repo_change
                apt_install remmina remmina-plugin-rdp remmina-plugin-vnc \
                            remmina-plugin-spice remmina-plugin-secret xdotool
            fi
            ;;
        debian|kali)
            apt_install remmina remmina-plugin-rdp remmina-plugin-vnc \
                        remmina-plugin-spice remmina-plugin-secret xdotool
            ;;
        *)
            log "ERROR: Unsupported distro: ${ID}" >&2
            exit 1
            ;;
    esac

    log "Step 2: Triggering UI and Profile configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Remmina installation complete!"
}

main "$@"
