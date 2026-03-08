#!/usr/bin/env bash
set -euo pipefail
IFS=$'
	'

###############################################################################
# install_wine.sh
#
# Intended to be called non-interactively from a Dockerfile to install
# WineHQ into a Kasm-enabled Ubuntu image.
###############################################################################

: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[WINE] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[WINE] ERROR: must be run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  echo "======= Installing Wine ======="

  apt_update_if_needed
  apt_install wget gnupg ca-certificates software-properties-common

  # Add 32-bit architecture
  dpkg --add-architecture i386
  apt_update_if_needed

  # Clean up any existing winehq sources and keys to prevent conflicts
  rm -f /etc/apt/sources.list.d/winehq*.sources /etc/apt/sources.list.d/winehq*.list
  rm -f /etc/apt/keyrings/winehq-archive.key /usr/share/keyrings/winehq-archive.pgp

  # Add WineHQ repository (using the same paths as the REMnux salt states)
  install -d -m 0755 /usr/share/keyrings
  wget -qO - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /usr/share/keyrings/winehq-archive.pgp

  local source_file="/etc/apt/sources.list.d/winehq.sources"
  cat <<EOF > "${source_file}"
Types: deb
URIs: https://dl.winehq.org/wine-builds/ubuntu
Suites: noble
Components: main
Architectures: amd64 i386
Signed-By: /usr/share/keyrings/winehq-archive.pgp
EOF

  # Force an update to pull in the newly added repo
  apt-get update

  # Install WineHQ staging (REMnux preferred version)
  apt_install --install-recommends winehq-staging

  log "Wine install complete."
}

main "$@"
