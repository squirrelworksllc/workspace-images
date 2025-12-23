#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# install_recoll.sh
#
# Debian-based only (Debian / Ubuntu)
# Installs Recoll (desktop full-text search)
# Project: https://www.recoll.org
#
# Ubuntu: optionally enables Recoll backports PPA:
#   ppa:recoll-backports/recoll-1.15-on
#
# NOTE: No cleanup here — repository cleanup is handled by your global cleanup
# script after all installers run.
###############################################################################

log() { echo "[recoll] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[recoll] ERROR: must be run as root" >&2
    exit 1
  fi
}

is_debian_based() {
  grep -qiE '(^ID=(debian|ubuntu)$|^ID_LIKE=.*debian)' /etc/os-release
}

is_ubuntu() {
  grep -qi '^ID=ubuntu$' /etc/os-release
}

# --- Start ---
require_root

if ! is_debian_based; then
  echo "[recoll] ERROR: Unsupported OS. Debian-based systems only." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Prefer your shared apt helpers when present.
APT_HELPER="/dockerstartup/install/ubuntu/install/common/00_apt_helper.sh"
if [ -f "$APT_HELPER" ]; then
  # shellcheck disable=SC1090
  . "$APT_HELPER"
  HAVE_APT_HELPER="true"
  log "Using apt helper: $APT_HELPER"
else
  HAVE_APT_HELPER="false"
  log "apt helper not found at $APT_HELPER; falling back to raw apt-get"
fi

apt_update() {
  if [ "$HAVE_APT_HELPER" = "true" ] && command -v apt_update_if_needed >/dev/null 2>&1; then
    apt_update_if_needed
  else
    apt-get update -y
  fi
}

apt_install_pkgs() {
  if [ "$HAVE_APT_HELPER" = "true" ] && command -v apt_install >/dev/null 2>&1; then
    apt_install "$@"
  else
    apt-get install -y --no-install-recommends "$@"
  fi
}

###############################################################################
# STEP 1: Install packages
###############################################################################
echo "============================================================"
echo "[recoll] STEP 1: Installing Recoll packages"
echo "============================================================"

apt_update

if is_ubuntu; then
  log "Ubuntu detected - attempting to enable Recoll backports PPA (optional)"
  apt_install_pkgs software-properties-common

  if add-apt-repository -y ppa:recoll-backports/recoll-1.15-on; then
    log "PPA added successfully"
    apt_update
  else
    log "WARNING: Could not add Recoll PPA; continuing with Ubuntu repo packages"
  fi
else
  log "Debian detected - using distribution packages"
fi

# Ubuntu/Debian package names:
# - recoll      (core)
# - recollgui   (GUI / desktop entry)
# - recollcmd   (CLI utilities, includes recollindex tools)
apt_install_pkgs recoll recollgui recollcmd

###############################################################################
# STEP 2: Desktop integration (if applicable)
###############################################################################
echo "============================================================"
echo "[recoll] STEP 2: Desktop integration"
echo "============================================================"

REC_DESKTOP_1="/usr/share/applications/recollgui.desktop"
REC_DESKTOP_2="/usr/share/applications/recoll.desktop"

if [ -f "$REC_DESKTOP_1" ]; then
  log "Desktop entry present: $REC_DESKTOP_1"
elif [ -f "$REC_DESKTOP_2" ]; then
  log "Desktop entry present: $REC_DESKTOP_2"
else
  log "No Recoll desktop entry found (non-fatal)"
fi

###############################################################################
# STEP 3: Profile / defaults (if applicable)
###############################################################################
echo "============================================================"
echo "[recoll] STEP 3: Default configuration / profiles"
echo "============================================================"

log "No system-wide Recoll defaults configured (per-user config lives in ~/.recoll)"

###############################################################################
# STEP 4: Verification
###############################################################################
echo "============================================================"
echo "[recoll] STEP 4: Verification"
echo "============================================================"

if command -v recoll >/dev/null 2>&1; then
  log "recoll found: $(command -v recoll)"
else
  echo "[recoll] ERROR: recoll binary not found after install" >&2
  exit 1
fi

if command -v recollindex >/dev/null 2>&1; then
  log "recollindex found: $(command -v recollindex)"
else
  log "recollindex not found (non-fatal)"
fi

log "Installation complete"
echo "Recoll is now Installed!"
