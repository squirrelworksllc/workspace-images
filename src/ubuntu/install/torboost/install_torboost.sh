#!/usr/bin/env bash
# Install torboost into a dedicated Python virtualenv (no system Python pollution).
# Intended for Dockerfile use on Ubuntu/Debian variants.
#
# Assumptions:
# - Standard Kasm user is UID/GID 1000
#
# Env overrides:
#   TORBOOST_VERSION   (default: latest)
#   TORBOOST_VENV_DIR  (default: /opt/torboost-venv)

set -euo pipefail

log() { echo "[torboost] $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "[torboost] ERROR: must run as root" >&2
    exit 1
  fi
}

# Source shared apt helper functions used across this repo.
# In Docker builds, installers live under: /dockerstartup/install/ubuntu/install/**.
source_apt_helpers() {
  local candidates=(
    "/dockerstartup/install/ubuntu/install/common/00_apt_helper.sh"
    "${SCRIPT_DIR}/../common/00_apt_helper.sh"
    "${SCRIPT_DIR}/../common/00_apt_helpers.sh"
  )

  for f in "${candidates[@]}"; do
    if [[ -r "$f" ]]; then
      # shellcheck disable=SC1090
      . "$f"
      return 0
    fi
  done

  echo "[torboost] ERROR: could not locate apt helper script (00_apt_helper.sh)" >&2
  return 1
}

require_helpers() {
  local missing=0
  for fn in apt_update_if_needed apt_install; do
    if ! command -v "$fn" >/dev/null 2>&1; then
      echo "[torboost] ERROR: missing helper function: $fn" >&2
      missing=1
    fi
  done
  [[ "$missing" -eq 0 ]]
}

main() {
  require_root
  source_apt_helpers
  require_helpers

  local kasm_uid=1000
  local kasm_gid=1000

  local venv_dir="${TORBOOST_VENV_DIR:-/opt/torboost-venv}"
  local torboost_version="${TORBOOST_VERSION:-}"

  echo "Step 1: Installing system prerequisites..."
  apt_update_if_needed
  # venv isolates Python installs from system Python (PEP 668 safe)
  apt_install ca-certificates python3 python3-venv python3-pip tor

  echo "Step 2: Creating torboost virtualenv at ${venv_dir}..."
  rm -rf "$venv_dir"
  python3 -m venv "$venv_dir"

  echo "Step 3: Upgrading pip tooling inside the venv..."
  "${venv_dir}/bin/python" -m pip install --no-cache-dir --upgrade pip setuptools wheel

  echo "Step 4: Installing torboost into the venv..."
  if [[ -n "$torboost_version" ]]; then
    log "Using pinned torboost version: ${torboost_version}"
    "${venv_dir}/bin/python" -m pip install --no-cache-dir "torboost==${torboost_version}"
  else
    log "Installing latest torboost"
    "${venv_dir}/bin/python" -m pip install --no-cache-dir torboost
  fi

  echo "Step 5: Creating wrapper at /usr/local/bin/torboost..."
  install -m 0755 -d /usr/local/bin
  cat >/usr/local/bin/torboost <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "${venv_dir}/bin/torboost" "\$@"
EOF
  chmod 0755 /usr/local/bin/torboost

  echo "Step 6: Setting ownership for standard Kasm user (${kasm_uid}:${kasm_gid})..."
  chown -R "${kasm_uid}:${kasm_gid}" "$venv_dir"

  echo "Step 7: Verifying install..."
  command -v tor >/dev/null 2>&1
  command -v torboost >/dev/null 2>&1
  torboost --help >/dev/null 2>&1 || true

  echo "Step 8: Done."
  log "torboost installed in venv: ${venv_dir}"
  log "run: torboost --help"
}

main "$@"
