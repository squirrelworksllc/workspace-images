#!/usr/bin/env bash
###############################################################################
# install_google_chrome.sh
# Purpose: Installs Google Chrome with Advanced Wrappers & Desktop Shortcut
###############################################################################
set -euo pipefail

# Kasm-specific paths
: "${INST_DIR:=/dockerstartup/install}"
# Source apt helper for SquirrelWorks standard updates
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[CHROME-INSTALL] $*"; }

create_desktop_shortcut() {
    log "Creating Desktop shortcut..."
    
    # Define the Desktop directory for both the current image build user 
    # and the skeleton directory for new session persistence.
    DESKTOP_DIRS=("/home/kasm_user/Desktop" "/etc/skel/Desktop")
    SHORTCUT_FILE="google-chrome.desktop"

    for DIR in "${DESKTOP_DIRS[@]}"; do
        mkdir -p "$DIR"
        cat <<EOF > "$DIR/$SHORTCUT_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Google Chrome
Comment=Access the Internet
Exec=/usr/bin/google-chrome-stable --no-sandbox --disable-dev-shm-usage
Icon=google-chrome
Categories=Network;WebBrowser;
EOF
        # Ensure kasm_user (1000) owns the shortcut in their home dir
        if [[ "$DIR" == "/home/kasm_user/Desktop" ]]; then
            chown 1000:1000 "$DIR/$SHORTCUT_FILE"
        fi
        chmod +x "$DIR/$SHORTCUT_FILE"
    done
}

main() {
    log "======= Installing Google Chrome Stable ======="

    ARCH="$(dpkg --print-architecture)"
    if [ "${ARCH}" = "arm64" ]; then
        log "Chrome not supported on arm64, skipping."
        exit 0
    fi

    apt_update_if_needed
    apt_install wget ca-certificates

    CHROME_VERSION="${1:-}"
    if [ -n "${CHROME_VERSION}" ]; then
        log "Downloading pinned version: ${CHROME_VERSION}"
        wget -q "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}_amd64.deb" -O /tmp/chrome.deb
    else
        log "Downloading latest current version..."
        wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O /tmp/chrome.deb
    fi

    # Install the deb and handle dependencies automatically
    apt-get install -y /tmp/chrome.deb
    rm -f /tmp/chrome.deb

    # Generate the Desktop Icon
    create_desktop_shortcut

    log "Triggering advanced UI and Policy configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Google Chrome installation complete."
}

main "$@"
