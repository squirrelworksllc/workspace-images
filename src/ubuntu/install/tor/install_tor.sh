#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# install_tor.sh
#
# Debian-based only (Debian / Ubuntu)
# Installs the Tor daemon (system tor) and optionally writes a minimal config.
#
# Docker-friendly behavior:
# - Installs packages only (does NOT rely on services starting during build)
# - Does NOT force-enable/start tor.service
#
# Cleanup:
# - Repository and package cleanup is handled by your global cleanup script
#   executed after all application installers.
#
# Env overrides:
#   TOR_PACKAGE          (default: tor)
#   TOR_GEOIP_PACKAGE    (default: tor-geoipdb)
#   TOR_DISABLE_SERVICE  (default: true)   # mask/disable service in images
#   TOR_WRITE_TORRC      (default: true)
#   TOR_TORRC_PATH       (default: /etc/tor/torrc)
#   TOR_SOCKS_PORT       (default: 9050)
#   TOR_CONTROL_PORT     (default: 9051)
#   TOR_COOKIE_AUTH      (default: true)
#   TOR_LOG_LEVEL        (default: notice) # debug|info|notice|warn|err
###############################################################################

log() { echo "[tor] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[tor] ERROR: must be run as root" >&2
    exit 1
  fi
}

is_debian_based() {
  command -v apt-get >/dev/null 2>&1
}

apt_update_if_needed() {
  # Prefer your global helper if present
  if command -v apt_update_if_needed >/dev/null 2>&1; then
    log "using global apt_update_if_needed() helper"
    return 0
  fi

  # Basic local implementation: skip update if recent (<24h)
  local stamp="/var/lib/apt/periodic/update-success-stamp"
  if [ -e "$stamp" ]; then
    local now ts age
    now="$(date +%s)"
    ts="$(stat -c %Y "$stamp" 2>/dev/null || echo 0)"
    age=$(( now - ts ))
    if [ "$age" -lt 86400 ]; then
      log "apt lists present and fresh; skipping apt-get update"
      return 0
    fi
  fi

  log "running apt-get update"
  apt-get update -y
}

apt_install() {
  # Prefer your centralized helper if present
  if command -v apt_install >/dev/null 2>&1; then
    log "using global apt_install() helper"
    apt_install "$@"
    return 0
  fi

  log "installing packages via apt-get: $*"
  DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "$@"
}

maybe_write_torrc() {
  local torrc_path="$1"
  local socks_port="$2"
  local control_port="$3"
  local cookie_auth="$4"
  local log_level="$5"

  log "writing minimal torrc: $torrc_path"
  mkdir -p "$(dirname "$torrc_path")"

  # Notes:
  # - Keep it minimal so it plays nice with Tor Browser if you also install it.
  # - CookieAuthentication is a sane default; ControlPort is optional but handy.
  # - We bind to localhost only.
  cat >"$torrc_path" <<EOF
###############################################################################
# /etc/tor/torrc
#
# Minimal Tor daemon configuration for container/workspace use.
# - SOCKS proxy on localhost
# - Optional ControlPort on localhost
#
# You can tune logging by setting TOR_LOG_LEVEL at build time.
###############################################################################

# Keep listeners local-only
SocksPort 127.0.0.1:${socks_port}

# ControlPort is optional; keep local-only as well
ControlPort 127.0.0.1:${control_port}

# Authentication for ControlPort
CookieAuthentication $( [ "$cookie_auth" = "true" ] && echo 1 || echo 0 )

# Logging (to stdout isn't typical for tor; this uses file-based logging)
# If you prefer journald, omit this and let systemd handle it on a real host.
Log ${log_level} file /var/log/tor/notices.log
EOF

  # Ensure tor log dir exists with correct perms-ish
  mkdir -p /var/log/tor
  chmod 0700 /var/log/tor || true

  chmod 0644 "$torrc_path"
  log "torrc written"
}

disable_tor_service_if_possible() {
  # In many images, systemd isn't PID1, but packages may still drop units.
  # This step is "best effort": if systemctl exists, we disable/mask.
  if ! command -v systemctl >/dev/null 2>&1; then
    log "systemctl not present; skipping tor.service disable/mask"
    return 0
  fi

  log "disabling/masking tor.service (best effort; docker-build friendly)"
  systemctl disable tor.service >/dev/null 2>&1 || true
  systemctl mask tor.service >/dev/null 2>&1 || true
  log "tor.service disable/mask attempted"
}

main() {
  log "starting tor installation"

  require_root
  log "running as root"

  if ! is_debian_based; then
    echo "[tor] ERROR: apt-get not found; Debian-based system required" >&2
    exit 1
  fi
  log "Debian-based system detected"

  local tor_pkg="${TOR_PACKAGE:-tor}"
  local geoip_pkg="${TOR_GEOIP_PACKAGE:-tor-geoipdb}"

  local disable_service="${TOR_DISABLE_SERVICE:-true}"
  local write_torrc="${TOR_WRITE_TORRC:-true}"
  local torrc_path="${TOR_TORRC_PATH:-/etc/tor/torrc}"
  local socks_port="${TOR_SOCKS_PORT:-9050}"
  local control_port="${TOR_CONTROL_PORT:-9051}"
  local cookie_auth="${TOR_COOKIE_AUTH:-true}"
  local log_level="${TOR_LOG_LEVEL:-notice}"

  log "package selected: ${tor_pkg}"
  log "geoip package selected: ${geoip_pkg}"
  log "write torrc: ${write_torrc}"
  log "disable service: ${disable_service}"
  log "socks port: ${socks_port}"
  log "control port: ${control_port}"

  log "checking apt metadata state"
  apt_update_if_needed

  log "installing tor packages"
  apt_install "$tor_pkg" "$geoip_pkg"

  log "verifying tor binary is available"
  if ! command -v tor >/dev/null 2>&1; then
    echo "[tor] ERROR: tor binary not found after installation" >&2
    exit 1
  fi

  log "tor installed successfully"
  log "tor version: $(tor --version 2>/dev/null | head -n 1 || echo unknown)"

  if [ "$write_torrc" = "true" ]; then
    maybe_write_torrc "$torrc_path" "$socks_port" "$control_port" "$cookie_auth" "$log_level"
  else
    log "skipping torrc write (TOR_WRITE_TORRC=false)"
  fi

  if [ "$disable_service" = "true" ]; then
    disable_tor_service_if_possible
  else
    log "leaving tor.service alone (TOR_DISABLE_SERVICE=false)"
  fi

  log "tor install complete"
}

main "$@"
