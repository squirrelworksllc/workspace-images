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

log "Step 2: Deploying Desktop Shortcut..."
SRC_DESKTOP="/usr/share/applications/libreoffice-startcenter.desktop"

if [ -f "$SRC_DESKTOP" ]; then
    mkdir -p "$KASM_HOME/Desktop"
    # Create a cleaner name on the desktop
    cp "$SRC_DESKTOP" "$KASM_HOME/Desktop/LibreOffice.desktop"
    chmod +x "$KASM_HOME/Desktop/LibreOffice.desktop"
    
    # Noble fix: Ensure icons are properly mapped
    sed -i 's/Icon=libreoffice-startcenter/Icon=libreoffice-main/g' "$KASM_HOME/Desktop/LibreOffice.desktop"
fi

# Ownership sync
chown -R 1000:1000 "$KASM_HOME/.config/libreoffice" "$KASM_HOME/Desktop"

log "LibreOffice UI configuration complete."
