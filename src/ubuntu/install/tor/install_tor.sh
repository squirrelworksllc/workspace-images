#!/usr/bin/env bash
###############################################################################
# install_tor.sh
# Purpose: Installs and configures the Tor daemon for Kasm 1.18+
###############################################################################
set -euo pipefail
LOG_TAG="TOR-DAEMON"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

maybe_write_torrc() {
  local torrc_path="$1"
  local socks_port="$2"
  local control_port="$3"
  local cookie_auth="$4"
  local log_level="$5"

  log "Writing SquirrelWorks torrc: $torrc_path"
  mkdir -p "$(dirname "$torrc_path")"

  cat >"$torrc_path" <<EOF
# Minimal Tor configuration for Kasm Workspaces
SocksPort 127.0.0.1:${socks_port}
ControlPort 127.0.0.1:${control_port}
CookieAuthentication $( [ "$cookie_auth" = "true" ] && echo 1 || echo 0 )

# Logging to file (Ensure debian-tor owns the directory)
Log ${log_level} file /var/log/tor/notices.log

# Data directory
DataDirectory /var/lib/tor
EOF

  # FIX: Permissions for the debian-tor user
  log "Fixing directory permissions for debian-tor..."
  mkdir -p /var/log/tor /var/lib/tor /run/tor
  chown -R debian-tor:debian-tor /var/log/tor /var/lib/tor /run/tor
  chmod 0700 /var/lib/tor /var/log/tor

  chmod 0644 "$torrc_path"
}

main() {
  require_root
  log "Starting Tor daemon installation..."

  # Env Defaults
  local socks_port="${TOR_SOCKS_PORT:-9050}"
  local control_port="${TOR_CONTROL_PORT:-9051}"
  local log_level="${TOR_LOG_LEVEL:-notice}"
  local torrc_path="${TOR_TORRC_PATH:-/etc/tor/torrc}"

  # Step 1: Install
  apt_update_if_needed
  apt_install tor tor-geoipdb

  # Step 2: Configure
  maybe_write_torrc "$torrc_path" "$socks_port" "$control_port" "true" "$log_level"

  # Step 3: Disable/Mask systemd service (Kasm uses custom startup scripts)
  if command -v systemctl >/dev/null 2>&1; then
      systemctl disable tor 2>/dev/null || true
      systemctl mask tor 2>/dev/null || true
  fi

  log "Tor daemon install complete. CLI available via 'tor'."
}

main "$@"
