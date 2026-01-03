#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

log() { echo "[wallpaper] $*"; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "[wallpaper] ERROR: must run as root" >&2
    exit 1
  fi
}

write_xfce_desktop_xml() {
  local home_dir="$1"
  local img_path="$2"

  local xml_dir="${home_dir}/.config/xfce4/xfconf/xfce-perchannel-xml"
  local xml_file="${xml_dir}/xfce4-desktop.xml"

  install -m 0755 -d "$xml_dir"

  # XFCE stores wallpaper per monitor/workspace. Kasm/XFCE commonly uses "monitor0".
  # We set monitor0 + monitor1 and workspace0 + workspace1 to cover most layouts.
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
}

main() {
  require_root

  # Where your repo copies resources into the image (because you COPY ./src/ubuntu -> ${INST_DIR}/ubuntu)
  local inst_dir="${INST_DIR:-/dockerstartup/install}"
  local resource_img="${inst_dir}/ubuntu/resources/images/noble_numbat_bg.png"

  # Where wallpapers should live inside the image (simple + standard)
  local target_img="/usr/share/backgrounds/noble_numbat_bg.png"

  if [[ ! -f "$resource_img" ]]; then
    echo "[wallpaper] ERROR: wallpaper not found at ${resource_img}" >&2
    exit 1
  fi

  log "Installing wallpaper to ${target_img}"
  install -m 0755 -d /usr/share/backgrounds
  install -m 0644 "$resource_img" "$target_img"

  log "Writing XFCE wallpaper config for default profile + kasm-user"
  write_xfce_desktop_xml "/home/kasm-default-profile" "$target_img"
  write_xfce_desktop_xml "/home/kasm-user" "$target_img"

  # Ensure ownership for the user homes (UID 1000 is your standard)
  chown -R 1000:0 /home/kasm-default-profile/.config /home/kasm-user/.config || true

  log "Done."
}

main "$@"
