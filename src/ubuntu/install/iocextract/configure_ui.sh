#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
#
# Purpose: Applications-menu entry (Utility / Security) and an opt-in Desktop
#          icon for iocextract.
#
# iocextract has no upstream GUI - it is a library + CLI - so the launcher opens
# it in a terminal with a file picker (falls through to stdin / file args when
# run from a shell).
###############################################################################
set -euo pipefail

log() { echo "[IOCEXTRACT-UI] $*"; }

# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Configuring iocextract UI..."

cat > /usr/share/applications/iocextract.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=iocextract
GenericName=IOC Extractor
Comment=Extract URLs, IPs, domains, emails, hashes and YARA rules from a document
Exec=xfce4-terminal --title=iocextract --command=/usr/local/bin/iocextract
Icon=utilities-terminal
Terminal=false
Categories=Utility;Security;
Keywords=ioc;threat;intel;indicator;forensics;malware;
EOF
chmod 0644 /usr/share/applications/iocextract.desktop

if command -v update-desktop-database > /dev/null; then
    update-desktop-database /usr/share/applications/
fi

# Desktop icon (opt-in via IOCEXTRACT_DESKTOP_ICON=true; default off)
desktop_icon iocextract /usr/share/applications/iocextract.desktop false

log "iocextract UI configuration applied."
