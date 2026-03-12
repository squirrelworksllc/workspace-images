#!/usr/bin/env bash
###############################################################################
# install_tor_browser.sh
#
# Purpose: Securely installs Tor Browser via Tarball + GPG verification.
# Target: Kasm 1.18+ (Ubuntu Noble / Debian)
###############################################################################
set -euo pipefail
IFS=$'\n\t'

log() { echo "[tor-browser-install] $*"; }

# Source Kasm apt helpers
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cleanup for the GPG/Download temp space
tmp=""
cleanup() { [[ -n "${tmp:-}" ]] && rm -rf "${tmp}"; }
trap cleanup EXIT

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *)
      log "ERROR: unsupported architecture: $(uname -m)" >&2
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
    echo "ERROR: unable to auto-detect Tor Browser version" >&2
    exit 1
  fi

  echo "$ver"
}

main() {
    log "======= Installing Tor Browser (Kasm 1.18+ Standard) ======="
    
    local install_dir="${TORBROWSER_INSTALL_DIR:-/opt/tor-browser}"
    local arch=$(detect_arch)
    
    local version="${TORBROWSER_VERSION:-}"
    if [[ -z "$version" ]]; then
        version=$(detect_latest_version)
        log "Detected latest version: ${version}"
    else
        log "Using pinned version: ${version}"
    fi
    
    local base_url="https://www.torproject.org/dist/torbrowser/${version}"
    local tarball="tor-browser-linux-${arch}-${version}.tar.xz"
    local sig="${tarball}.asc"

    tmp="$(mktemp -d)"

    log "Step 2: Installing prerequisites..."
    apt_update_if_needed

    log "Step 3: Downloading Tor Browser tarball and signature..."
    curl -fL --retry 3 --retry-delay 2 -o "${tmp}/${tarball}" "${base_url}/${tarball}"
    curl -fL --retry 3 --retry-delay 2 -o "${tmp}/${sig}"     "${base_url}/${sig}"

    log "Step 4: Fetching Tor Browser Developers signing key (WKD)..."
    local expected_fp="EF6E286DDA85EA2A4BA7DE684E2C6E8793298290"

    export GNUPGHOME="${tmp}/gnupg"
    install -m 0700 -d "$GNUPGHOME"

    gpg --batch --auto-key-locate nodefault,wkd \
        --locate-keys torbrowser@torproject.org >/dev/null

    log "Step 5: Verifying signing key fingerprint..."
    local got_fp
    got_fp="$(gpg --batch --with-colons --fingerprint torbrowser@torproject.org \
      | awk -F: '$1=="fpr"{print $10; exit}')"

    if [[ "$got_fp" != "$expected_fp" ]]; then
      log "ERROR: signing key fingerprint mismatch!" >&2
      log "Expected: ${expected_fp}" >&2
      log "Got:      ${got_fp:-<none>}" >&2
      exit 1
    fi

    log "Step 6: Verifying Tor Browser tarball signature..."
    gpg --batch --output "${tmp}/tor.keyring" --export "${expected_fp}" >/dev/null
    gpgv --keyring "${tmp}/tor.keyring" "${tmp}/${sig}" "${tmp}/${tarball}"

    log "Extracting to ${install_dir}"
    rm -rf "${install_dir}"
    mkdir -p "${install_dir}"
    tar -xJf "${tmp}/tor-browser-linux-${arch}-${version}.tar.xz" -C "${install_dir}" --strip-components=1

    # Ensure UID 1000 owns the install so the internal updater works
    chown -R 1000:1000 "${install_dir}"

    log "Creating CLI wrapper"
    cat >/usr/local/bin/tor-browser <<EOF
#!/usr/bin/env bash
exec "${install_dir}/Browser/start-tor-browser" "--detach" "\$@"
EOF
    chmod 0755 /usr/local/bin/tor-browser

    log "Step 9: Executing UI integration"
    if [[ -x "${SCRIPT_DIR}/integrate_tor_browser_desktop.sh" ]]; then
        TORBROWSER_INSTALL_DIR="${install_dir}" bash "${SCRIPT_DIR}/integrate_tor_browser_desktop.sh"
    fi

    log "Tor Browser ${version} install complete."
}

main "$@"