#!/usr/bin/env bash
###############################################################################
# desktop_integration.sh
#
# Everything that makes this look and behave like a real BitCurator desktop:
# the XDG application menu (Forensics and Reporting, Imaging and Recovery,
# Packaging and Transfer, Documentation and Help, Additional Tools), the
# mount-policy tray app, dotfiles (.vimrc, ficlam, .bash_aliases), guymager
# config, and bundled documentation. Ported from bitcurator-salt's
# bitcurator/theme/, bitcurator/mounter/, and bitcurator/env/ - see
# vendor/NOTICE.md for what's copied verbatim vs. reimplemented.
#
# Everything here targets SYSTEM-WIDE paths (/usr/share, /etc/xdg) or the
# real Kasm session home passed in as $1 - there's no separate BitCurator
# user account to alias or reconcile (that whole uid-sharing headache from
# the Salt-based approach doesn't exist anymore).
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[BITCURATOR-DESKTOP] $*"; }

KASM_HOME="${1:?usage: desktop_integration.sh <kasm-home>}"
VENDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/vendor" && pwd)"

deploy_menu() {
  log "Installing the BitCurator application menu..."
  mkdir -p /etc/xdg/menus/applications-merged /usr/share/desktop-directories
  install -m 0644 "${VENDOR_DIR}/menu-config/"*.menu /etc/xdg/menus/applications-merged/
  install -m 0644 "${VENDOR_DIR}/menu-config/"*.directory /usr/share/desktop-directories/
  install -m 0644 "${VENDOR_DIR}/menu-config/"*.desktop /usr/share/applications/
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications/ || true
}

deploy_icons() {
  log "Installing BitCurator icons..."
  mkdir -p /usr/share/icons/bitcurator /usr/share/pixmaps/bitcurator /usr/share/pixmaps/mounter
  cp -a "${VENDOR_DIR}/icons/bitcurator/." /usr/share/icons/bitcurator/
  cp -a "${VENDOR_DIR}/pixmaps/bitcurator/." /usr/share/pixmaps/bitcurator/
  cp -a "${VENDOR_DIR}/pixmaps/mounter/." /usr/share/pixmaps/mounter/
}

deploy_run_wrappers() {
  log "Installing the run-<tool>.sh terminal wrappers..."
  install -m 0755 "${VENDOR_DIR}/usr-local-bin/"* /usr/local/bin/
  install -m 0755 "${VENDOR_DIR}/usr-sbin/"* /usr/sbin/
}

deploy_mounter() {
  log "Installing the BitCurator mount-policy app..."
  install -m 0755 "${VENDOR_DIR}/mounter/bc_mounter.py" /usr/local/bin/bc_mounter.py
  install -m 0755 "${VENDOR_DIR}/mounter/bc_policyapp.py" /usr/local/bin/bc_policyapp.py
  mkdir -p "${KASM_HOME}/.config/autostart"
  install -m 0755 "${VENDOR_DIR}/mounter/bcpolicyapp.py.desktop" \
    "${KASM_HOME}/.config/autostart/bcpolicyapp.py.desktop"
}

deploy_dotfiles() {
  log "Installing dotfiles (.vimrc, .vim, .bash_aliases, ficlam)..."
  install -m 0644 "${VENDOR_DIR}/env/.vimrc" "${KASM_HOME}/.vimrc"
  mkdir -p "${KASM_HOME}/.vim/colors" "${KASM_HOME}/.vim/backups" "${KASM_HOME}/.vim/swaps"
  cp -a "${VENDOR_DIR}/env/.vim/colors/." "${KASM_HOME}/.vim/colors/"

  local aliases="${KASM_HOME}/.bash_aliases"
  touch "$aliases"
  grep -qi 'alias mountwin' "$aliases" || \
    echo "alias mountwin='mount -o ro,loop,show_sys_files,streams_interface=windows'" >> "$aliases"

  mkdir -p "${KASM_HOME}/.fiwalk"
  install -m 0755 "${VENDOR_DIR}/env/ficlam.sh" "${KASM_HOME}/.fiwalk/ficlam.sh"

  # Desktop -> /media, matching a stock BitCurator desktop's shortcut to
  # wherever imagemounter/guymager land mounted volumes.
  ln -sfn /media "${KASM_HOME}/Desktop/Shared Folders and Media" 2>/dev/null || true
}

deploy_guymager_config() {
  log "Installing guymager config..."
  mkdir -p /usr/share/guymager /etc/guymager
  install -m 0644 "${VENDOR_DIR}/env/guymager/guymager_en-CH.qm" /usr/share/guymager/guymager_en-CH.qm
  install -m 0644 "${VENDOR_DIR}/env/guymager/local.cfg" /etc/guymager/local.cfg
}

deploy_documentation() {
  log "Installing bundled BitCurator documentation..."
  cp -a "${VENDOR_DIR}/documentation/." "${KASM_HOME}/"
}

deploy_gpl_notice() {
  # GPLv3 compliance: keep the license and attribution reachable from the
  # running image, not just this source repo.
  mkdir -p /usr/share/doc/bitcurator5
  install -m 0644 "${VENDOR_DIR}/LICENSE-GPLv3.txt" /usr/share/doc/bitcurator5/LICENSE-GPLv3.txt
  install -m 0644 "${VENDOR_DIR}/NOTICE.md" /usr/share/doc/bitcurator5/NOTICE.md
}

deploy_thunar_actions() {
  # The nautilus scripts above (~/.local/share/nautilus/scripts) only show up
  # if Nautilus is the file manager; this Kasm desktop uses XFCE's Thunar,
  # which has its own custom-actions mechanism (~/.config/Thunar/uca.xml).
  # Covers the core forensics workflow rather than porting all of upstream's
  # nautilus scripts - these are new wrapper scripts we wrote, not modified
  # copies of the vendored nautilus scripts (which stay untouched so they
  # still work verbatim if Nautilus is ever present instead).
  log "Installing Thunar custom actions (BitCurator's file-manager actions)..."
  mkdir -p /usr/local/bin
  cat > /usr/local/bin/bc-mount-image <<'EOF'
#!/bin/bash
sudo imount --no-interaction --pretty --mountdir /media "$@" 2>&1 | \
  zenity --text-info --title "Mount Disk Image Volumes" --width=640 --height=480
EOF
  cat > /usr/local/bin/bc-unmount-images <<'EOF'
#!/bin/bash
sudo imount --pretty --unmount --mountdir /media
EOF
  cat > /usr/local/bin/bc-calculate-md5 <<'EOF'
#!/bin/bash
for f in "$@"; do md5sum "$f"; done | zenity --text-info --title "MD5" --width=640 --height=480
EOF
  chmod 0755 /usr/local/bin/bc-mount-image /usr/local/bin/bc-unmount-images /usr/local/bin/bc-calculate-md5

  mkdir -p "${KASM_HOME}/.config/Thunar"
  local uca="${KASM_HOME}/.config/Thunar/uca.xml"
  [ -f "$uca" ] || printf '<?xml version="1.0" encoding="UTF-8"?>\n<actions>\n</actions>\n' > "$uca"
  if ! grep -q 'bc-mount-image' "$uca"; then
    sed -i 's#</actions>#\
  <action>\
    <icon>drive-removable-media</icon>\
    <name>Mount Disk Image (imagemounter)</name>\
    <unique-id>bc-mount-image</unique-id>\
    <command>bc-mount-image %F</command>\
    <patterns>*</patterns>\
    <startup-notify/>\
    <directories/>\
    <other-files/>\
  </action>\
  <action>\
    <icon>media-eject</icon>\
    <name>Unmount All Disk Images</name>\
    <unique-id>bc-unmount-images</unique-id>\
    <command>bc-unmount-images</command>\
    <patterns>*</patterns>\
    <directories/>\
    <other-files/>\
  </action>\
  <action>\
    <icon>text-x-generic</icon>\
    <name>Calculate MD5</name>\
    <unique-id>bc-calculate-md5</unique-id>\
    <command>bc-calculate-md5 %F</command>\
    <patterns>*</patterns>\
    <audio-files/>\
    <image-files/>\
    <other-files/>\
    <text-files/>\
    <video-files/>\
  </action>\
</actions>#' "$uca"
  fi
  chown -R 1000:0 "${KASM_HOME}/.config/Thunar"
}

main() {
  deploy_menu
  deploy_icons
  deploy_run_wrappers
  deploy_mounter
  deploy_dotfiles
  deploy_guymager_config
  deploy_documentation
  deploy_gpl_notice
  deploy_thunar_actions
  chown -R 1000:0 "${KASM_HOME}"
  log "Desktop integration complete."
}

main "$@"
