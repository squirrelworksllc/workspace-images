#!/usr/bin/env bash
###############################################################################
# 00_apt_helper.sh
# Purpose: High-resiliency Apt wrapper for SquirrelWorks 1.1 Registry
###############################################################################

# Force non-interactive and silence all prompts
export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"
export DEBIAN_PRIORITY="critical"
: "${SKIP_CLEAN:=false}"

log() { echo "[APT-HELPER] [$(date -u +%F\ %T)] $*"; }

# Strip env vars that commonly break apt/dpkg in container builds
apt_sanitize_env() {
  unset LD_PRELOAD || true
  unset LD_LIBRARY_PATH || true
  unset DYLD_LIBRARY_PATH || true
  unset PYTHONPATH || true
  unset PERL5LIB || true
}

apt_wait_for_locks() {
  # Best-effort wait for the four main apt/dpkg lock points
  local i
  for i in {1..60}; do
    if ! fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
      && ! fuser /var/lib/dpkg/lock >/dev/null 2>&1 \
      && ! fuser /var/cache/apt/archives/lock >/dev/null 2>&1 \
      && ! fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
      return 0
    fi
    log "Apt/Dpkg lock detected; waiting... (${i}/60)"
    sleep 1
  done
  log "WARNING: Proceeding despite persistent locks (Risky)."
  return 0
}

apt_get() {
  apt_sanitize_env
  apt_wait_for_locks
  # Disable Use-Pty to keep logs clean and avoid terminal-related hangs
  command apt-get -o Dpkg::Use-Pty=0 "$@"
}

apt_install() {
  if [ "$#" -eq 0 ]; then
    log "No packages specified; skipping."
    return 0
  fi

  log "Installing: $*"
  set +e
  # Noble fix: Ensure we retry on connection drops which are common in cloud builds
  apt_get install -y --no-install-recommends \
          -o Acquire::Retries=5 \
          -o Acquire::http::Timeout="60" \
          "$@"
  local rc=$?
  set -e

  # Segfault (139) Handler - Common in QEMU/Emulated builds
  if [ "$rc" -eq 139 ]; then
    log "WARNING: Apt segfaulted (139). Retrying with minimal environment..."
    apt_sanitize_env
    apt_wait_for_locks
    command apt-get install -y --no-install-recommends "$@"
    rc=$?
  fi

  return "$rc"
}

apt_lists_present() {
  [ -d /var/lib/apt/lists ] && find /var/lib/apt/lists -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | grep -q .
}

apt_update_if_needed() {
  if apt_lists_present; then
    log "Apt lists already present; skipping update."
    return 0
  fi

  log "Apt lists missing; refreshing sources..."
  set +e
  apt_get update -o Acquire::Retries=5
  local rc=$?
  set -e

  if [ "$rc" -eq 139 ]; then
    log "WARNING: Apt update segfaulted. Retrying..."
    apt_sanitize_env
    command apt-get update
    rc=$?
  fi
  return "$rc"
}

apt_cleanup() {
  if [ "${SKIP_CLEAN}" = "true" ]; then
    log "SKIP_CLEAN=true; preserving apt cache."
    return 0
  fi

  log "Purging apt cache and temporary build artifacts..."
  apt_wait_for_locks
  apt_sanitize_env
  command apt-get clean -y || true
  rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* || true
}

apt_refresh_after_repo_change() {
  log "Repository sources updated; refreshing..."
  apt_sanitize_env
  apt_wait_for_locks
  command apt-get update -o Acquire::Retries=5 -o Dpkg::Use-Pty=0
}
