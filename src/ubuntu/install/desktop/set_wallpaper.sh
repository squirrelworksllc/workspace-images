#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# XFCE Wallpaper Setup Script (Kasm / Ubuntu Noble)
#
# Purpose:
# - Install a static wallpaper image into /usr/share/backgrounds
# - Pre-seed XFCE wallpaper configuration so it applies automatically
#   for both:
#     - kasm-default-profile (template profile)
#     - kasm-user            (runtime user, UID 1000)
#
# Notes:
# - XFCE reads xfconf XML at session startup
# - Kasm sessions are ephemeral; settings must exist BEFORE login
# - We explicitly set multiple monitors/workspaces to avoid edge cases
###############################################################################

log() { echo "[wallpaper] $*"; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "[wallpaper] ERROR: must run as root" >&2
    exit 1
  fi
}

###############################################################################
# write_xfce_desktop_xml <home_dir> <image_path>
#
# Writes xfce4-desktop.xml directly into a user's xfconf directory.
# This predefines the wallpaper without needing a live X session.
###############################################################################
write_xfce_desktop_xml() {
  local home_dir="$1"
  local img_path="$2"

  log "Configuring XFCE wallpaper XML for home: ${home_dir}"
  log "Wallpaper image path: ${img_path}"

  local xml_dir="${home_dir}/.config/xfce4/xfconf/xfce-perchannel-xml"
  local xml_file="${xml_dir}/xfce4-desktop.xml"

  log "Ensuring xfconf directory exists: ${xml_dir}"
  install -m 0755 -d "$xml_dir"

  # XFCE stores wallpaper per:
  #   screen -> monitor -> workspace
  #
  # We explicitly define:
  #   - monitor0 + monitor1
  #   - workspace0 + workspace1
  #
  # This avoids:
  #   - black background on secondary monitors
  #   - background reverting on workspace switch
  log "Writing xfce4-desktop.xml"

  cat >"$xml_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop">
    <property name="screen0">

      <property name="monitor0">
        <property name="workspace0">
          <property name="image-path" type="string" value="${img_path}"/>
          <property name="last-image" type="string" value="${img_path}"/>
          <property name="image-style" type="int" value="5"/>
        </property>
        <property name="workspace1">
          <property name="image-path" type="string" value="${img_path}"/>
          <property name="last-image" type="string" value="${img_path}"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>

      <property name="monitor1">
        <property name="workspace0">
          <property name="image-path" type="string" value="${img_path}"/>
          <property name="last-image" type="string" value="${img_path}"/>
          <property name="image-style" type="int" value="5"/>
        </property>
        <property name="workspace1">
          <property name="image-path" type="string" value="${img_path}"/>
          <property name="last-image" type="string" value="${img_path}"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>

    </property>
  </property>
</channel>
EOF

  chmod 0644 "$xml_file"
  log "Wrote ${xml_file}"
}

###############################################################################
# Main
###############################################################################
main() {
  require_root

  log "Starting XFCE wallpaper installation"

  # This is where your Dockerfile copies repo content:
  #   COPY ./src/ubuntu -> /dockerstartup/install/ubuntu
  local inst_dir="${INST_DIR:-/dockerstartup/install}"
  local resource_img="${inst_dir}/ubuntu/resources/images/noble_numbat_bg.png"

  # Standard, predictable system location for wallpapers
  local target_img="/usr/share/backgrounds/noble_numbat_bg.png"

  log "Expected source image: ${resource_img}"
  log "Target wallpaper path: ${target_img}"

  if [[ ! -f "$resource_img" ]]; then
    echo "[wallpaper] ERROR: wallpaper not found at ${resource_img}" >&2
    exit 1
  fi

  log "Installing wallpaper into /usr/share/backgrounds"
  install -m 0755 -d /usr/share/backgrounds
  install -m 0644 "$resource_img" "$target_img"

  log "Applying wallpaper configuration for XFCE users"

  # Template profile (used when Kasm creates user sessions)
  write_xfce_desktop_xml "/home/kasm-default-profile" "$target_img"

  # Actual runtime user (whoami == kasm-user)
  write_xfce_desktop_xml "/home/kasm-user" "$target_img"

  log "Fixing ownership on xfconf directories (UID 1000)"
  chown -R 1000:0 \
    /home/kasm-default-profile/.config \
    /home/kasm-user/.config \
    || true

  log "Wallpaper setup complete"
}

main "$@"
