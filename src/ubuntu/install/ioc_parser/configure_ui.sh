#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Sets up desktop shortcuts or UI hooks for IOC Parser.
###############################################################################
set -euo pipefail

log() { echo "[IOC-PARSER-UI] $*"; }

main() {
    log "Configuring UI elements for IOC Parser..."
    
    mkdir -p /usr/share/applications
    
    # Create an XFCE start menu entry that launches a terminal instance
    cat << 'EOF' > /usr/share/applications/ioc-parser.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=IOC Parser
Comment=Parse Indicators of Compromise from documents
Exec=xfce4-terminal -e "/usr/local/bin/ioc-parser --help"
Icon=utilities-terminal
Terminal=false
Categories=Utility;Security;
EOF

    # Ensure kasm_user (UID 1000) maintains access
    chmod 644 /usr/share/applications/ioc-parser.desktop

    log "UI configuration applied successfully."
}

main "$@"
