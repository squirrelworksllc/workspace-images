#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Applications-menu entry + optional Desktop icon for IOC Parser.
###############################################################################
set -euo pipefail

log() { echo "[IOC-PARSER-UI] $*"; }

# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Configuring IOC Parser UI..."

cat > /usr/share/applications/ioc-parser.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=IOC Parser
GenericName=Indicator Extractor
Comment=Extract URLs, IPs, domains, emails and hashes from a document
Exec=xfce4-terminal --title=IOC-Parser --command=/usr/local/bin/ioc-parser
Icon=utilities-terminal
Terminal=false
Categories=Utility;Security;
Keywords=ioc;threat;intel;indicator;forensics;
EOF
chmod 0644 /usr/share/applications/ioc-parser.desktop

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

# Desktop icon (opt-in via IOC_PARSER_DESKTOP_ICON=true; default off)
desktop_icon ioc_parser /usr/share/applications/ioc-parser.desktop false

log "IOC Parser UI configuration applied."
