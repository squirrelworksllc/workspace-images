#!/usr/bin/env bash
# Desktop integration for Tor Browser already installed on the filesystem.
# - Installs a system .desktop file so Kasm/Desktop sees it immediately
# - Extracts icons into /usr/share/icons/hicolor for consistent launcher icons
#
# Env overrides:
#   TORBROWSER_INSTALL_DIR    (default: /opt/tor-browser)
#   TORBROWSER_DESKTOP_ID     (default: tor-browser)
#   TORBROWSER_APP_NAME       (default: Tor Browser)
#   TORBROWSER_CATEGORIES     (default: Network;WebBrowser;)
#   TORBROWSER_ICON_NAME      (default: tor-browser)

set -euo pipefail

log() { echo "[tor-browser-desktop] $*"; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "[tor-browser-desktop] ERROR: must run as root" >&2
    exit 1
  fi
}

main() {
  require_root

  local install_dir="${TORBROWSER_INSTALL_DIR:-/opt/tor-browser}"
  local desktop_id="${TORBROWSER_DESKTOP_ID:-tor-browser}"
  local app_name="${TORBROWSER_APP_NAME:-Tor Browser}"
  local categories="${TORBROWSER_CATEGORIES:-Network;WebBrowser;}"
  local icon_name="${TORBROWSER_ICON_NAME:-tor-browser}"

  local start_bin="${install_dir}/start-tor-browser.desktop"

  echo "Step 1: Validating Tor Browser install..."
  if [[ ! -x "$start_bin" ]]; then
    echo "[tor-browser-desktop] ERROR: Tor Browser not found at: ${start_bin}" >&2
    exit 1
  fi

  echo "Step 2: Extracting icons into /usr/share/icons/hicolor..."
  # Tor Browser typically stores icons here:
  #   /opt/tor-browser/browser/chrome/icons/default/
  # Files are usually named like:
  #   default16.png default32.png default48.png default64.png default128.png default256.png
  local icon_src_dir="${install_dir}/browser/chrome/icons/default"

  if [[ ! -d "$icon_src_dir" ]]; then
    echo "[tor-browser-desktop] WARN: icon source directory not found: ${icon_src_dir}" >&2
  else
    # Copy common sizes if present; ignore missing sizes gracefully.
    for size in 16 32 48 64 128 256; do
      local src="${icon_src_dir}/default${size}.png"
      local dst_dir="/usr/share/icons/hicolor/${size}x${size}/apps"
      local dst="${dst_dir}/${icon_name}.png"

      if [[ -f "$src" ]]; then
        install -m 0755 -d "$dst_dir"
        install -m 0644 "$src" "$dst"
      fi
    done
  fi

  # Refresh icon cache if available (not always installed in minimal images)
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    echo "Step 3: Updating icon cache..."
    gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
  else
    echo "Step 3: Skipping icon cache update (gtk-update-icon-cache not installed)..."
  fi

  echo "Step 4: Installing system desktop entry..."
  local desktop_path="/usr/share/applications/${desktop_id}.desktop"

  # Note: absolute Exec + Icon name ensures reliable discovery in Kasm/desktop environments.
  cat >"$desktop_path" <<EOF
[Desktop Entry]
Type=Application
Name=${app_name}
Comment=Browse the web anonymously
Exec=${start_bin} --detach
Icon=${icon_name}
Categories=${categories}
Terminal=false
StartupNotify=true
StartupWMClass=Tor Browser
EOF

  chmod 0644 "$desktop_path"

  echo "Step 5: Desktop integration complete."
  log "Desktop entry: ${desktop_path}"
  log "Icon name: ${icon_name} (installed into hicolor sizes where available)"
}

main "$@"
