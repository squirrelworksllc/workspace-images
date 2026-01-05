#!/usr/bin/env bash
# Apt helper functions for Debian/Ubuntu Docker builds.
# Designed to be SOURCED by scripts (do not set strict mode here).

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"
: "${SKIP_CLEAN:=false}"

log() { echo "[apt] [$(date -u +%F\ %T)] $*"; }

# Strip env vars that commonly break apt/dpkg in container builds.
apt_sanitize_env() {
  unset LD_PRELOAD || true
  unset LD_LIBRARY_PATH || true
  unset DYLD_LIBRARY_PATH || true
  unset PYTHONPATH || true
  unset PERL5LIB || true

  # Optional: proxies can be kept if you rely on them; comment out if needed.
  # unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY || true
}

apt_wait_for_locks() {
  # Best-effort wait; avoids dpkg lock races.
  local i
  for i in {1..60}; do
    if ! fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
      && ! fuser /var/lib/dpkg/lock >/dev/null 2>&1 \
      && ! fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
      return 0
    fi
    log "apt/dpkg lock detected; waiting (${i}/60)"
    sleep 1
  done
  log "WARNING: apt/dpkg locks still present after waiting; proceeding anyway"
  return 0
}

apt_get() {
  # Wrapper that sanitizes env and disables PTY (more stable in CI/Docker).
  apt_sanitize_env
  apt_wait_for_locks
  command apt-get -o Dpkg::Use-Pty=0 "$@"
}

apt_install() {
  # Usage: apt_install pkg1 pkg2 ...
  if [ "$#" -eq 0 ]; then
    log "apt_install called with no packages; skipping"
    return 0
  fi

  log "installing: $*"
  set +e
  apt_get install -y --no-install-recommends -o Acquire::Retries=3 "$@"
  local rc=$?
  set -e

  # If apt-get segfaults it often returns 139.
  if [ "$rc" -eq 139 ]; then
    log "WARNING: apt-get returned 139 (segfault). Retrying once with extra-sanitized env."
    apt_sanitize_env
    # One more attempt, minimal flags
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
  apt_wait_for_locks
  if apt_lists_present; then
    log "apt lists present; skipping apt-get update"
    return 0
  fi

  log "apt lists missing; running apt-get update"
  set +e
  apt_get update -o Acquire::Retries=3
  local rc=$?
  set -e

  if [ "$rc" -eq 139 ]; then
    log "WARNING: apt-get update returned 139 (segfault). Retrying once with minimal flags."
    apt_sanitize_env
    apt_wait_for_locks
    command apt-get update
    rc=$?
  fi

  return "$rc"
}

apt_cleanup() {
  if [ "${SKIP_CLEAN}" = "true" ]; then
    log "SKIP_CLEAN=true; skipping cleanup"
    return 0
  fi

  log "cleaning apt cache and temp"
  apt_wait_for_locks
  apt_sanitize_env
  command apt-get clean -y -o Dpkg::Use-Pty=0 || true
  rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* || true
}

apt_refresh_after_repo_change() {
  log "apt sources changed; running apt-get update"
  apt_sanitize_env
  apt_wait_for_locks
  command apt-get update -o Acquire::Retries=3 -o Dpkg::Use-Pty=0
}
