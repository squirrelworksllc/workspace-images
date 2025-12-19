#!/usr/bin/env bash
# This is a helper file designed to modify the dockerfile and called scripts so that they only
# invoke "apt update" if new sources/keys/packages are added, cutting down redundancy.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# If you want to optionally skip cleanup via env:
: "${SKIP_CLEAN:=false}"

log() { echo "[$(date -u +%F\ %T)] $*"; }

apt_install() {
  # Usage: apt_install pkg1 pkg2 ...
  apt-get install -y --no-install-recommends "$@"
}

apt_update_if_needed() {
  # Only run update if apt lists are missing (common after cleanup layers)
  if [ ! -d /var/lib/apt/lists ] || [ -z "$(ls -A /var/lib/apt/lists 2>/dev/null)" ]; then
    log "apt lists missing; running apt-get update"
    apt-get update
  else
    log "apt lists present; skipping apt-get update"
  fi
}

apt_cleanup() {
  if [ "${SKIP_CLEAN}" = "true" ]; then
    log "SKIP_CLEAN=true; skipping cleanup"
    return 0
  fi
  apt-get clean
  rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
}

# Call this only in scripts that add repos/keys
apt_refresh_after_repo_change() {
  log "Apt sources changed; running apt-get update"
  apt-get update
}
