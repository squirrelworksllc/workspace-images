#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: UI hardening, Single-Window Mode, and Menu Fixes for GIMP
# Architecture: SquirrelWorks 1.1 - Clean Desktop Policy
###############################################################################
set -euo pipefail

log() { echo "[GIMP-UI] $*"; }

# Kasm 1.18+ Dynamic Home Detection
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Pre-configuring Single-Window Mode..."
# We target both 2.10 and 3.0 paths to ensure the 'floating window' issue 
# doesn't plague Kasm users regardless of the GIMP version installed.
for VERSION in "2.10" "3.0"; do
    GIMP_CONF_DIR="$KASM_HOME/.config/GIMP/$VERSION"
    mkdir -p "$GIMP_CONF_DIR"
    cat <<EOF > "$GIMP_CONF_DIR/sessionrc"
(session-info "toplevel"
    (factory-entry "gimp-empty-image-window")
    (single-window-mode yes)
    (launcher-kind-id 0))
EOF
done

log "Hardening Application Menu Entry..."
# Find the actual source desktop file
SRC_DESKTOP=$(find /opt/gimp/app -name "*.desktop" | head -n1)

if [ -n "$SRC_DESKTOP" ]; then
    # 1. Create a clean system-wide desktop entry
    cp "$SRC_DESKTOP" /usr/share/applications/gimp.desktop
    
    # 2. Fix Execution and Icon paths with Absolute References
    # Using absolute paths for Icons is the 'Gold Standard' to prevent broken UI icons.
    sed -i 's@Exec=.*@Exec=/opt/gimp/launcher@g' /usr/share/applications/gimp.desktop
    
    # Try to locate the best icon if the default isn't at /opt/gimp/app/gimp.png
    if [ -f "/opt/gimp/app/gimp.png" ]; then
        sed -i 's@Icon=.*@Icon=/opt/gimp/app/gimp.png@g' /usr/share/applications/gimp.desktop
    else
        # Fallback to standard GIMP icon search
        GIMP_ICON=$(find /opt/gimp/app -name "gimp.png" | head -n1 || echo "gimp")
        sed -i "s@Icon=.*@Icon=$GIMP_ICON@g" /usr/share/applications/gimp.desktop
    fi
    
    # 3. Clean Desktop Policy
    log "Removing desktop shortcut to maintain clean workspace..."
    rm -f "$KASM_HOME/Desktop/GIMP.desktop"
    rm -f "$KASM_HOME/Desktop/gimp.desktop"
    
    # 4. Update system database to register the new icon/path
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi
else
    log "WARNING: Source .desktop file not found in /opt/gimp/app."
fi

# Ensure permissions for the Kasm user (Noble runs the session user with group 0)
chown -R 1000:0 "$KASM_HOME/.config/GIMP" 2>/dev/null || true

log "GIMP UI configuration complete. Desktop clean, Menu hardened."
