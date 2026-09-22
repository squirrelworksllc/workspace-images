#!/usr/bin/env bash
###############################################################################
# configure_ui.sh (Desktop Module)
#
# Light-touch XFCE tweaks on top of the Kasm core image.
#
# Wallpaper: confirmed live (2026-09-12, kasm-user shell in a running dind
# session) that the profile xfce4-desktop.xml Kasm's own session seeds at
# runtime does NOT reference /usr/share/backgrounds/bg_default.png at all - it
# points every workspace at the stock /usr/share/backgrounds/xfce/xfce-shapes.svg.
# It also uses a monitor name of "monitorVNC-0", and - critically - nests a
# per-workspace property (workspace0..3) under the monitor, each carrying
# color-style/image-style/last-image; a flat monitor-level image-path (what we
# used to write) is not read by xfdesktop at all. set_wallpaper.sh still swaps
# the bytes of bg_default.png; this writes the xfce4-desktop.xml that actually
# points at it, in the schema xfdesktop expects, covering both "monitor0" and
# "monitorVNC-0" since the negotiated KasmVNC output name isn't guaranteed.
###############################################################################
set -e

log() { echo "[DESKTOP-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

# --- Wallpaper: point xfce4-desktop.xml at our branded bg_default.png ------
log "Registering the branded wallpaper in xfce4-desktop.xml..."
XFCE_DESKTOP_XML="$KASM_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
mkdir -p "$(dirname "$XFCE_DESKTOP_XML")"

_workspace_block() {
    cat <<EOF
        <property name="workspace${1}" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/bg_default.png"/>
        </property>
EOF
}

{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<channel name="xfce4-desktop" version="1.0">'
    echo '  <property name="backdrop" type="empty">'
    echo '    <property name="screen0" type="empty">'
    for _monitor in monitor0 monitorVNC-0; do
        echo "      <property name=\"${_monitor}\" type=\"empty\">"
        for _ws in 0 1 2 3; do
            _workspace_block "$_ws"
        done
        echo '      </property>'
    done
    echo '    </property>'
    echo '  </property>'
    echo '</channel>'
} > "$XFCE_DESKTOP_XML"

# --- 'Documentation' category in the Applications menu -----------------------
log "Creating the 'Documentation' Applications-menu category..."
mkdir -p /usr/share/desktop-directories
cat <<EOF > /usr/share/desktop-directories/xfce-documentation.directory
[Desktop Entry]
Type=Directory
Name=Documentation
Icon=help-browser
EOF

# XFCE's <DefaultMergeDirs/> resolves to xfce-applications-merged/; generic
# tools use applications-merged/. Write both.
DOC_MENU='<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
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
</Menu>'
for _merged in applications-merged xfce-applications-merged; do
    mkdir -p "/etc/xdg/menus/${_merged}"
    printf '%s\n' "$DOC_MENU" > "/etc/xdg/menus/${_merged}/documentation.menu"
done

# --- No screensaver / screen locker in a remote session ---------------------
# (otherwise xfce4-screensaver drops the floating XFCE mascot over the desktop).
# On desktop/remnux 01_cleanup.sh already does this; harmless no-op there.
log "Disabling screensaver / locker autostart..."
for _svc in xfce4-screensaver light-locker xscreensaver; do
    rm -f "/etc/xdg/autostart/${_svc}.desktop"
done

# --- Panel: drop the pulseaudio + workspace-pager plugins -------------------
# (unchanged from the long-standing behaviour on desktop / remnux)
PANEL_CONF="$KASM_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [ -f "$PANEL_CONF" ]; then
    sed -i '/value="pulseaudio"/d' "$PANEL_CONF"
    sed -i '/value="pager"/d' "$PANEL_CONF"
fi

# --- Whisker menu button icon ---------------------------------------------------
# Kasm's default is a broken 'X'; fall back to the distributor logo. Dedicated
# SquirrelWorks / Kasm-workspace branding is handled elsewhere.
WHISKER_CONF=$(find "$KASM_HOME/.config/xfce4/panel" -name "whiskermenu-*.rc" 2>/dev/null | head -n 1 || true)
if [ -n "$WHISKER_CONF" ] && [ -f "$WHISKER_CONF" ]; then
    sed -i 's/^button-icon=.*/button-icon=distributor-logo-ubuntu/g' "$WHISKER_CONF"
fi

chown -R 1000:0 "$KASM_HOME/.config/xfce4" 2>/dev/null || true
log "UI configuration complete."
