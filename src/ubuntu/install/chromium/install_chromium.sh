#!/usr/bin/env bash
###############################################################################
# install_chromium.sh
# Purpose: Installs native Chromium (non-snap) via Debian repo pinning.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[CHROMIUM-INSTALL] $*"; }

main() {
    log "======= Installing Chromium (Native DEB) ======="

    # Logic Check: Skip if Chrome is already present to save space
    : "${INSTALL_CHROME:=false}"
    : "${SKIP_CHROMIUM:=false}"
    if [ "${INSTALL_CHROME}" = "true" ] || [ "${SKIP_CHROMIUM}" = "true" ]; then
        log "Chrome is present or skip flag set. Aborting Chromium install."
        exit 0
    fi

    . /etc/os-release
    apt_update_if_needed

    if [ "${ID}" = "ubuntu" ]; then
        log "Ubuntu detected: Configuring Debian Repo pinning for native Chromium..."
        apt_install curl ca-certificates software-properties-common
        
        # Remove any existing snap-wrappers
        apt-get remove -y chromium-browser-l10n chromium-codecs-ffmpeg chromium-browser || true

        # Add Debian Bookworm repo for the binary
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://ftp-master.debian.org/keys/archive-key-12.asc -o /etc/apt/keyrings/debian-archive-key-12.asc
        echo "deb [signed-by=/etc/apt/keyrings/debian-archive-key-12.asc] http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list.d/debian-bookworm.list

        # Pinning: Ensure we ONLY get Chromium from Debian
        cat > /etc/apt/preferences.d/debian-bookworm <<'EOF'
Package: chromium chromium-common chromium-sandbox chromium-l10n
Pin: release n=bookworm
Pin-Priority: 990
EOF
        apt_refresh_after_repo_change
        apt_install chromium
        
        # Cleanup repo files to keep apt clean
        rm -f /etc/apt/sources.list.d/debian-bookworm.list /etc/apt/preferences.d/debian-bookworm
    else
        log "Distro ${ID} detected: Installing from native repos."
        apt_install chromium
    fi

    log "Triggering UI and Wrapper configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Chromium installation complete."
}

main "$@"
