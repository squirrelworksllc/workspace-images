#!/usr/bin/env bash
###############################################################################
# install_torboost.sh
#
# Purpose: Installs torboost and configures the Tor Control Port for Kasm 1.18+
###############################################################################
set -euo pipefail

log() { echo "[torboost-install] $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) "

# Source Kasm apt helpers
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    log "ERROR: must run as root" >&2
    exit 1
  fi
}

main() {
  require_root
  
  local kasm_uid=1000
  local venv_dir="${TORBOOST_VENV_DIR:-/opt/torboost-venv}"
  local torboost_version="${TORBOOST_VERSION:-}"

  log "Step 1: Installing system prerequisites..."
  apt_update_if_needed
  # We need 'tor' but also 'netcat' or 'curl' for health checks
  apt_install python3-venv python3-pip tor netcat-openbsd

  log "Step 2: Setting up Python venv at ${venv_dir}..."
  rm -rf "$venv_dir"
  python3 -m venv "$venv_dir"
  "${venv_dir}/bin/python" -m pip install --no-cache-dir --upgrade pip setuptools wheel

  log "Step 3: Installing torboost..."
  if [[ -n "$torboost_version" ]]; then
    "${venv_dir}/bin/python" -m pip install --no-cache-dir "torboost==${torboost_version}"
  else
    "${venv_dir}/bin/python" -m pip install --no-cache-dir torboost
  fi

  log "Step 4: Creating global wrapper..."
  cat >/usr/local/bin/torboost <<EOF
#!/usr/bin/env bash
# TorBoost Wrapper
exec "${venv_dir}/bin/torboost" "\$@"
EOF
  chmod 0755 /usr/local/bin/torboost

  log "Step 5: Configuring Tor for Control Port access (Required for TorBoost)..."
  # TorBoost needs to talk to Tor. We enable the ControlPort without a password 
  # for the local container environment.
  cat >>/etc/tor/torrc <<EOF
ControlPort 9051
CookieAuthentication 0
DataDirectory /var/lib/tor
EOF
  
  # Ensure the tor user/group can actually write to its data dir in the container
  mkdir -p /var/lib/tor
  chown -R debian-tor:debian-tor /var/lib/tor

  log "Step 6: Setting ownership for Kasm user..."
  chown -R 1000:1000 "$venv_dir"

  log "Step 7: Creating UI Configuration (Start Menu)..."
  if [[ -x "${SCRIPT_DIR}/configure_ui.sh" ]]; then
      bash "${SCRIPT_DIR}/configure_ui.sh"
  fi

  log "torboost installation complete!"
}

main "$@"
