#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# Kasm Default Background Override
#
# Kasm Workspaces uses /usr/share/backgrounds/bg_default.png
# as the enforced default wallpaper during session startup.
#
# The ONLY reliable way to set a custom default background is to
# replace that file in-place.
###############################################################################

log() { echo "[wallpaper] $*"; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "[wallpaper] ERROR: must run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  # Where the repo asset lives during build
  local inst_dir="${INST_DIR:-/dockerstartup/install}"
  local source_img="${inst_dir}/ubuntu/resources/images/noble_numbat_bg.png"

  # Where Kasm EXPECTS the default background
  local target_dir="/usr/share/backgrounds"
  local target_img="${target_dir}/bg_default.png"

  log "Kasm default background override starting"
  log "Source image: ${source_img}"
  log "Target image: ${target_img}"

  if [[ ! -f "$source_img" ]]; then
    echo "[wallpaper] ERROR: source image not found: ${source_img}" >&2
    exit 1
  fi

  log "Ensuring background directory exists"
  install -m 0755 -d "$target_dir"

  if [[ -f "$target_img" ]]; then
    log "Existing bg_default.png found — replacing it"
  else
    log "bg_default.png not found — creating it"
  fi

  install -m 0644 "$source_img" "$target_img"

  log "Kasm default background successfully replaced"
}

main "$@"
