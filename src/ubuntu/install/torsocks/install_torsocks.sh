#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# install_torsocks.sh
#
# Debian-based only (Debian / Ubuntu)
#
# Installs torsocks and applies defaults by copying torsocks.conf.
#
# Env overrides:
#   TORSOCKS_PACKAGE   (default: torsocks)
#   TORSOCKS_CONF_PATH (default: /etc/tor/torsocks.conf)
#   INSTALL_GUARD      (default: true)
#   GUARD_PATH         (default: /usr/local/bin/torsocks-guard)
###############################################################################

# Align with other installers (Slack, etc.)
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[torsocks] $*"; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[torsocks] ERROR: must be run as root" >&2
    exit 1
  fi
}

install_guard_helper() {
  local path="$1"

  log "installing torsocks guard helper -> ${path}"
  cat >"$path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

log() { echo "[torsocks] $*"; }

TOR_SOCKS_HOST="${TOR_SOCKS_HOST:-127.0.0.1}"
TOR_SOCKS_PORT="${TOR_SOCKS_PORT:-9050}"

check_socks() {
  (exec 3<>"/dev/tcp/${TOR_SOCKS_HOST}/${TOR_SOCKS_PORT}") >/dev/null 2>&1
}

case "${1:-status}" in
  on)
    check_socks || {
      echo "[torsocks] ERROR: Tor SOCKS not reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}" >&2
      exit 1
    }
    torsocks on >/dev/null 2>&1 || true
    log "torsocks enabled for this shell"
    ;;
  off)
    torsocks off >/dev/null 2>&1 || true
    log "torsocks disabled for this shell"
    ;;
  status)
    if check_socks; then
      log "Tor SOCKS reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}"
    else
      log "Tor SOCKS NOT reachable at ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}"
    fi
    ;;
  *)
    echo "Usage: torsocks-guard {on|off|status}" >&2
    exit 2
    ;;
esac
EOF

  chmod 0755 "$path"
}

main() {
  require_root

  # Fail early with a clear message if helper functions aren't present
  command -v apt_install >/dev/null 2>&1 || {
    echo "[torsocks] ERROR: apt_install not defined (apt helper not sourced?)" >&2
    exit 1
  }
  command -v apt_update_if_needed >/dev/null 2>&1 || {
    echo "[torsocks] ERROR: apt_update_if_needed not defined (apt helper not sourced?)" >&2
    exit 1
  }

  echo "======= Installing torsocks ======="

  local pkg="${TORSOCKS_PACKAGE:-torsocks}"
  local conf_path="${TORSOCKS_CONF_PATH:-/etc/tor/torsocks.conf}"
  local install_guard="${INSTALL_GUARD:-true}"
  local guard_path="${GUARD_PATH:-/usr/local/bin/torsocks-guard}"

  log "package selected: ${pkg}"

  log "checking apt metadata"
  apt_update_if_needed

  log "installing ${pkg}"
  apt_install "${pkg}"

  log "verifying torsocks binary"
  command -v torsocks >/dev/null 2>&1 || {
    echo "[torsocks] ERROR: torsocks not found after install" >&2
    exit 1
  }

  log "installing torsocks.conf -> ${conf_path}"
  mkdir -p "$(dirname "${conf_path}")"

  # Prefer a config shipped alongside this script
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

  if [ -f "${script_dir}/torsocks.conf" ]; then
    cp -f "${script_dir}/torsocks.conf" "${conf_path}"
  else
    echo "[torsocks] ERROR: missing torsocks.conf next to installer: ${script_dir}/torsocks.conf" >&2
    exit 1
  fi

  chmod 0644 "${conf_path}"

  if [ "${install_guard}" = "true" ]; then
    install_guard_helper "${guard_path}"
  else
    log "guard helper disabled (INSTALL_GUARD=false)"
  fi

  log "torsocks install complete"
}

main "$@"
