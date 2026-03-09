#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: UI hardening and Desktop integration for GIMP
###############################################################################
set -euo pipefail

log() { echo "[GIMP-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Pre-configuring Single-Window Mode..."
# GIMP 3.x uses ~/.config/GIMP/3.0/
GIMP_CONF_DIR="$KASM_HOME/.config/GIMP/3.0"
mkdir -p "$GIMP_CONF_DIR"

# Set sessionrc to force single-window mode so tools don't float away in Kasm
cat <<EOF > "$GIMP_CONF_DIR/sessionrc"
(session-info "toplevel"
    (factory-entry "gimp-empty-image-window")
    (single-window-mode yes)
    (launcher-kind-id 0))
EOF

log "Deploying Desktop Shortcut..."
SRC_DESKTOP=$(find /opt/gimp/app -name "*.desktop" | head -n1)

if [ -n "$SRC_DESKTOP" ]; then
    cp "$SRC_DESKTOP" /usr/share/applications/gimp.desktop
    
    # Update paths
    sed -i 's@Exec=.*@Exec=/opt/gimp/launcher@g' /usr/share/applications/gimp.desktop
    sed -i 's@Icon=.*@Icon=/opt/gimp/app/gimp.png@g' /usr/share/applications/gimp.desktop
    
    # Copy to Desktop
    mkdir -p "$KASM_HOME/Desktop"
    cp /usr/share/applications/gimp.desktop "$KASM_HOME/Desktop/GIMP.desktop"
    chmod +x "$KASM_HOME/Desktop/GIMP.desktop"
    
    # Update system database
    [ -x "$(command -v update-desktop-database)" ] && update-desktop-database /usr/share/applications/
fi

chown -R 1000:1000 "$KASM_HOME/.config/GIMP" "$KASM_HOME/Desktop"

log "GIMP UI configuration successfully applied."
