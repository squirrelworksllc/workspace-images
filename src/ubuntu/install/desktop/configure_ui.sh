#!/usr/bin/env bash
# Forces XFCE/X11 to recognize the new default at the user level
set -e

log() { echo "[DESKTOP-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

log "Registering wallpaper in XFCE config..."
mkdir -p "$KASM_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"

# This XML blob tells XFCE exactly which file to use for the backdrop
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

chown -R 1000:1000 "$KASM_HOME/.config/xfce4"
