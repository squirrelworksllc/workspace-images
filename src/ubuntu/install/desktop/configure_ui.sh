#!/usr/bin/env bash
# Forces XFCE/X11 to recognize the new default at the user level
set -e

log() { echo "[DESKTOP-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Registering wallpaper in XFCE config..."
mkdir -p "$KASM_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"

log "Creating a dedicated 'Documentation' category in the Applications menu..."
# 1. Create the Directory definition
mkdir -p /usr/share/desktop-directories
cat <<EOF > /usr/share/desktop-directories/xfce-documentation.directory
[Desktop Entry]
Type=Directory
Name=Documentation
Icon=help-browser
EOF

# 2. Merge it into the XFCE Applications menu
mkdir -p /etc/xdg/menus/applications-merged
cat <<EOF > /etc/xdg/menus/applications-merged/documentation.menu
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
  "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>Documentation</Name>
    <Directory>xfce-documentation.directory</Directory>
    <Include>
      <Category>Documentation</Category>
    </Include>
  </Menu>
</Menu>
EOF

# 3. Apply Wallpaper XML
cat <<EOF > "$KASM_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string" value="/usr/share/backgrounds/bg_default.png"/>
        <property name="last-image" type="string" value="/usr/share/backgrounds/bg_default.png"/>
      </property>
    </property>
  </property>
</channel>
EOF

# 4. Panel Cleanups (Fix PulseAudio, Workspace Switcher, and Missing 'X' Icon)
log "Cleaning up XFCE Panel elements (PulseAudio, Workspaces, and Icon)..."
PANEL_CONF="$KASM_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [ -f "$PANEL_CONF" ]; then
    # Remove the pulseaudio plugin from the panel memory
    sed -i '/value="pulseaudio"/d' "$PANEL_CONF"
    
    # Remove the multi-desktop workspace switcher (pager plugin)
    sed -i '/value="pager"/d' "$PANEL_CONF"
fi

# Locate the Whisker Menu config and swap the broken 'X' for the standard Ubuntu Logo
WHISKER_CONF=$(find "$KASM_HOME/.config/xfce4/panel" -name "whiskermenu-*.rc" 2>/dev/null | head -n 1 || true)
if [ -n "$WHISKER_CONF" ] && [ -f "$WHISKER_CONF" ]; then
    sed -i 's/^button-icon=.*/button-icon=distributor-logo-ubuntu/g' "$WHISKER_CONF"
fi

chown -R 1000:0 "$KASM_HOME/.config/xfce4" 2>/dev/null || true
log "UI Configuration Complete."
