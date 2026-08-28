#!/usr/bin/env bash
###############################################################################
# install_torsocks.sh
# Optimized for SquirrelWorks Kasm 1.18+
###############################################################################
set -euo pipefail
IFS=$'\n\t'

: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[torsocks-install] $*"; }

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
  log "======= Installing torsocks Environment ======="
  
  apt_update_if_needed
  apt_install torsocks
  
  # Deploy the custom config
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local conf_path="/etc/tor/torsocks.conf"
  
  if [ -f "${script_dir}/torsocks.conf" ]; then
    cp -f "${script_dir}/torsocks.conf" "${conf_path}"
    chmod 0644 "${conf_path}"
    log "Applied SquirrelWorks torsocks.conf"
  fi

  # Deploy the Guard Helper
  install_guard_helper "/usr/local/bin/torsocks-guard"

  # Register the runtime validator so runtime_validation.sh picks it up at
  # session start (kept out of the ephemeral install tree on purpose).
  if [ -f "${script_dir}/validate_torsocks.sh" ]; then
    install -d -m 0755 /dockerstartup/tools/validators
    install -m 0755 "${script_dir}/validate_torsocks.sh" \
      /dockerstartup/tools/validators/torsocks.sh
    log "Registered torsocks runtime validator"
  fi

  # Trigger UI Integration
  if [ -f "${script_dir}/configure_ui.sh" ]; then
    bash "${script_dir}/configure_ui.sh"
  fi

  log "torsocks installation complete."
}

main "$@"
