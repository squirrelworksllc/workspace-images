#!/usr/bin/env bash
# Install Tor Browser from the official Tor Project tarball with OpenPGP
# signature verification, then perform desktop integration.
#
# - No Tor daemon
# - Hardened tarball + signature verification
# - Desktop integration is automatically executed from the same directory
# - Intended to be called from a Dockerfile (Ubuntu/Debian, Kasm images)
#
# Assumptions:
# - Standard Kasm user (UID/GID 1000)
# - If this script runs, Tor Browser is wanted and desktop integration is required
#
# Env overrides:
#   TORBROWSER_VERSION     (default: auto-detect latest)
#   TORBROWSER_INSTALL_DIR (default: /opt/tor-browser)

set -euo pipefail

log() { echo "[tor-browser] $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global temp dir so EXIT trap can always see it (avoid "tmp: unbound variable" with set -u)
tmp=""
cleanup() {
  [[ -n "${tmp:-}" ]] && rm -rf "${tmp}"
}
trap cleanup EXIT

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "[tor-browser] ERROR: must run as root" >&2
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

  echo "[tor-browser] ERROR: could not locate apt helper script (00_apt_helper.sh)" >&2
  return 1
}

require_helpers() {
  local missing=0
  for fn in apt_update_if_needed apt_install; do
    if ! command -v "$fn" >/dev/null 2>&1; then
      echo "[tor-browser] ERROR: missing helper function: $fn" >&2
      missing=1
    fi
  done
  [[ "$missing" -eq 0 ]]
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *)
      echo "[tor-browser] ERROR: unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

detect_latest_version() {
  local html ver
  html="$(curl -fsSL https://www.torproject.org/download/)"

  ver="$(printf '%s' "$html" \
    | grep -oE 'tor-browser-linux-[^"]+-([0-9]+\.[0-9]+(\.[0-9]+)?)\.tar\.xz' \
    | head -n1 \
    | sed -E 's/.*-([0-9]+\.[0-9]+(\.[0-9]+)?)\.tar\.xz/\1/')"

  if [[ -z "${ver:-}" ]]; then
    echo "[tor-browser] ERROR: unable to auto-detect Tor Browser version" >&2
    exit 1
  fi

  echo "$ver"
}

main() {
  require_root
  source_apt_helpers
  require_helpers

  # Standard Kasm user
  local owner_uid=1000
  local owner_gid=1000

  local install_dir="${TORBROWSER_INSTALL_DIR:-/opt/tor-browser}"

  local arch version base_url tarball sig
  arch="$(detect_arch)"

  echo "Step 1: Determining Tor Browser version..."
  version="${TORBROWSER_VERSION:-}"
  if [[ -z "$version" ]]; then
    version="$(detect_latest_version)"
    log "Detected latest version: ${version}"
  else
    log "Using pinned version: ${version}"
  fi

  base_url="https://www.torproject.org/dist/torbrowser/${version}"
  tarball="tor-browser-linux-${arch}-${version}.tar.xz"
  sig="${tarball}.asc"

  tmp="$(mktemp -d)"

  echo "Step 2: Installing prerequisites..."
  apt_update_if_needed
  # gpgv is sometimes separate; include explicitly for predictable builds
  apt_install ca-certificates curl gnupg gpgv xz-utils tar

  echo "Step 3: Downloading Tor Browser tarball and signature..."
  curl -fL --retry 3 --retry-delay 2 -o "${tmp}/${tarball}" "${base_url}/${tarball}"
  curl -fL --retry 3 --retry-delay 2 -o "${tmp}/${sig}"     "${base_url}/${sig}"

  echo "Step 4: Fetching Tor Browser Developers signing key (WKD)..."
  # Official Tor Browser Developers signing key fingerprint
  local expected_fp="EF6E286DDA85EA2A4BA7DE684E2C6E8793298290"

  export GNUPGHOME="${tmp}/gnupg"
  install -m 0700 -d "$GNUPGHOME"

  gpg --batch --auto-key-locate nodefault,wkd \
      --locate-keys torbrowser@torproject.org >/dev/null

  echo "Step 5: Verifying signing key fingerprint..."
  local got_fp
  got_fp="$(gpg --batch --with-colons --fingerprint torbrowser@torproject.org \
    | awk -F: '$1=="fpr"{print $10; exit}')"

  if [[ "$got_fp" != "$expected_fp" ]]; then
    echo "[tor-browser] ERROR: signing key fingerprint mismatch!" >&2
    echo "[tor-browser] Expected: ${expected_fp}" >&2
    echo "[tor-browser] Got:      ${got_fp:-<none>}" >&2
    exit 1
  fi

  echo "Step 6: Verifying Tor Browser tarball signature..."
  gpg --batch --output "${tmp}/tor.keyring" --export "${expected_fp}" >/dev/null
  gpgv --keyring "${tmp}/tor.keyring" "${tmp}/${sig}" "${tmp}/${tarball}"

  echo "Step 7: Installing Tor Browser to ${install_dir}..."
  rm -rf "${install_dir}"
  install -m 0755 -d "${install_dir}"

  tar -xJf "${tmp}/${tarball}" \
      -C "${install_dir}" \
      --strip-components=1

  # Allow standard Kasm user to update Tor Browser at runtime
  chown -R "${owner_uid}:${owner_gid}" "${install_dir}"

  echo "Step 8: Creating CLI launcher..."
  install -m 0755 -d /usr/local/bin
  cat >/usr/local/bin/tor-browser <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "${install_dir}/start-tor-browser.desktop" "\$@"
EOF
  chmod 0755 /usr/local/bin/tor-browser

  echo "Step 9: Running desktop integration..."
  local desktop_script="${SCRIPT_DIR}/integrate_tor_browser_desktop.sh"

  if [[ ! -x "$desktop_script" ]]; then
    echo "[tor-browser] ERROR: desktop integration script not found or not executable:" >&2
    echo "  ${desktop_script}" >&2
    exit 1
  fi

  TORBROWSER_INSTALL_DIR="${install_dir}" \
    "$desktop_script"

  echo "Step 10: Tor Browser installation and integration complete."
  log "Tor Browser ${version} installed and registered for Kasm desktop"
}

main "$@"
