#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Configures Remmina preferences, profiles, and UI hygiene.
###############################################################################
set -euo pipefail

log() { echo "[REMMINA-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Step 1: Applying global preferences..."
PREF_DIR="$KASM_HOME/.config/remmina"
mkdir -p "$PREF_DIR"

# If you have the remmina.pref file alongside the script, use it.
if [ -f "$SCRIPT_DIR/remmina.pref" ]; then
    cp "$SCRIPT_DIR/remmina.pref" "$PREF_DIR/remmina.pref"
else
    # Fallback: Create the silent prefs if file is missing.
    # Leave datadir/screenshot paths unset so Remmina uses its own ~-relative
    # defaults at runtime (baking $KASM_HOME here points at the build-time home).
    cat <<EOF > "$PREF_DIR/remmina.pref"
[remmina_pref]
disable_tray_icon=true
[usage_stats]
periodic_usage_stats_permitted=false
[remmina_news]
periodic_news_permitted=false
EOF
fi

log "Step 2: Deploying default connection templates..."
# Remmina uses .remmina files for connection templates
TEMPLATE_DIR="$KASM_HOME/.local/share/remmina"
mkdir -p "$TEMPLATE_DIR"

cat <<EOF > "$TEMPLATE_DIR/default_rdp.remmina"
[remmina]
name=Default RDP
protocol=RDP
ignore-tls-errors=1
viewmode=4
resolution_mode=2
EOF

log "Step 3: UI Integration (Desktop & Start Menu)..."
# Remmina's desktop file name changed in newer versions (org.remmina.Remmina)
DESKTOP_FILE="/usr/share/applications/org.remmina.Remmina.desktop"
if [ ! -f "$DESKTOP_FILE" ]; then
    DESKTOP_FILE="/usr/share/applications/remmina.desktop"
fi

if [ -f "$DESKTOP_FILE" ]; then
    # Ensure it's in 'Network' and 'RemoteAccess' categories
    sed -i 's/Categories=.*/Categories=Network;RemoteAccess;/g' "$DESKTOP_FILE"
fi

# Step 4: Disable Autostart (Remmina loves to linger in the background)
log "Disabling background autostart..."
mkdir -p "$KASM_HOME/.config/autostart"
cat <<EOF > "$KASM_HOME/.config/autostart/remmina-applet.desktop"
[Desktop Entry]
Type=Application
Name=Remmina Applet
Exec=remmina -i
X-GNOME-Autostart-enabled=false
NoDisplay=true
EOF

# Noble runs the session user with primary group 0
chown -R 1000:0 "$KASM_HOME/.config" "$KASM_HOME/.local" 2>/dev/null || true

log "Remmina UI configuration complete."
