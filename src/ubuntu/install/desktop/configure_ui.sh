#!/usr/bin/env bash
###############################################################################
# configure_ui.sh (Desktop Module)
#
# Light-touch XFCE tweaks on top of the Kasm core image. We deliberately do NOT
# rewrite Kasm's own xfce4-desktop.xml / xfce4-panel.xml - Kasm already ships a
# working set (with the right monitorVNC-* backdrop entries), and overwriting
# them broke the wallpaper and the panel. The wallpaper is changed the
# Kasm-documented way: set_wallpaper.sh swaps /usr/share/backgrounds/bg_default.png,
# which Kasm's shipped config already points at.
###############################################################################
set -e

log() { echo "[DESKTOP-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

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
