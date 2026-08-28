#!/usr/bin/env bash
###############################################################################
# integrate_tor_browser_desktop.sh
# 
# Purpose: Registers Tor Browser in the system menu and Kasm desktop.
###############################################################################
set -euo pipefail
IFS=$'\n\t'

log() { echo "[tor-browser-ui] $*"; }

# Standard for Kasm 1.18+: Detect home of the primary user (UID 1000)
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

main() {
    local install_dir="${TORBROWSER_INSTALL_DIR:-/opt/tor-browser}"
    local start_bin="${install_dir}/Browser/start-tor-browser"
    
    log "Installing system-wide Start Menu entry..."
    local desktop_path="/usr/share/applications/tor-browser.desktop"
    
    cat >"$desktop_path" <<EOF
[Desktop Entry]
Type=Application
Name=Tor Browser
Comment=Secure & Anonymous Browsing
Exec=${start_bin} --detach
Icon=${install_dir}/Browser/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
Terminal=false
StartupNotify=true
EOF
    chmod 0644 "$desktop_path"

    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi

    # Desktop icon (opt-in via TOR_BROWSER_DESKTOP_ICON; default ON for the browser)
    desktop_icon tor_browser "$desktop_path" true "Tor Browser.desktop"

    log "UI integration complete"
}

main "$@"
