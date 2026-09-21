#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: UI hardening and performance tweaks for LibreOffice
###############################################################################
set -euo pipefail

log() { echo "[LIBREOFFICE-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Step 1: Applying performance and UI silence policies..."
# LibreOffice stores settings in registrymodifications.xcu
# We pre-create this to disable "Tip of the Day" and splash screens
CONF_DIR="$KASM_HOME/.config/libreoffice/4/user"
mkdir -p "$CONF_DIR"

# Disable the "Tip of the Day" popup and Java checking
cat <<EOF > "$CONF_DIR/registrymodifications.xcu"
<?xml version="1.0" encoding="UTF-8"?>
<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="ShowTipOfTheDay" oor:op="fuse"><value>false</value></prop></item>
<item oor:path="/org.openoffice.Office.Common/Java/Applet"><prop oor:name="Enable" oor:op="fuse"><value>false</value></prop></item>
</oor:items>
EOF

log "Step 2: Start Menu Integration..."
SRC_DESKTOP="/usr/share/applications/libreoffice-startcenter.desktop"

# Fix LD_LIBRARY_PATH in all LibreOffice desktop files to prevent crashes.
# .desktop Exec lines do not do command substitution, so the multiarch triplet
# must be resolved here at build time (not left as a literal "$(arch)").
log "Applying LD_LIBRARY_PATH fix to LibreOffice shortcuts..."
MULTIARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo "$(arch)-linux-gnu")"
if ls /usr/share/applications/libreoffice-*.desktop 1> /dev/null 2>&1; then
    sed -i "s@Exec=libreoffice@Exec=env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:/usr/lib/${MULTIARCH}/ libreoffice@g" /usr/share/applications/libreoffice-*.desktop
fi

if [ -f "$SRC_DESKTOP" ]; then
    # Noble fix: Ensure icons are properly mapped
    sed -i 's/Icon=libreoffice-startcenter/Icon=libreoffice-main/g' "$SRC_DESKTOP"
fi

# Ownership sync (Noble runs the session user with primary group 0)
chown -R 1000:0 "$KASM_HOME/.config/libreoffice" 2>/dev/null || true

log "LibreOffice UI configuration complete."
