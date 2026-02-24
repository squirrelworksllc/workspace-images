#!/usr/bin/env bash
# Desktop integration for Tor Browser already installed on the filesystem.
# - Installs a system .desktop file so Kasm/Desktop sees it immediately
# - Extracts icons into /usr/share/icons/hicolor for consistent launcher icons
# - Places a Desktop shortcut for the standard Kasm user
# - Marks .desktop launchers executable to avoid "Run/Display" prompts in XFCE
#
# Env overrides:
#   TORBROWSER_INSTALL_DIR      (default: /opt/tor-browser)
#   TORBROWSER_DESKTOP_ID       (default: tor-browser)
#   TORBROWSER_APP_NAME         (default: Tor Browser)
#   TORBROWSER_CATEGORIES       (default: Network;WebBrowser;)
#   TORBROWSER_ICON_NAME        (default: tor-browser)
#   TORBROWSER_DESKTOP_UID      (default: 1000)   # standard Kasm user UID
#   TORBROWSER_DESKTOP_GID      (default: 1000)
#   TORBROWSER_DESKTOP_HOME     (default: auto-detect via getent; fallback /home/kasm-user)
#   TORBROWSER_DESKTOP_FILENAME (default: Tor Browser.desktop)

set -euo pipefail
IFS=$'\n\t'

log() { echo "[tor-browser-desktop] $*"; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "[tor-browser-desktop] ERROR: must run as root" >&2
    exit 1
  fi
}

detect_home_for_uid() {
  local uid="$1"
  local home
  home="$(getent passwd "$uid" | awk -F: '{print $6}' || true)"
  if [[ -n "${home:-}" ]]; then
    printf '%s\n' "$home"
  else
    printf '%s\n' "/home/kasm-user"
  fi
}

main() {
  require_root

  local install_dir="${TORBROWSER_INSTALL_DIR:-/opt/tor-browser}"
  local desktop_id="${TORBROWSER_DESKTOP_ID:-tor-browser}"
  local app_name="${TORBROWSER_APP_NAME:-Tor Browser}"
  local categories="${TORBROWSER_CATEGORIES:-Network;WebBrowser;}"
  local icon_name="${TORBROWSER_ICON_NAME:-tor-browser}"

  # The *real* launcher we should use everywhere (menu/desktop/CLI)
  local start_bin="${install_dir}/Browser/start-tor-browser"

  echo "Step 1: Validating Tor Browser install..."
  if [[ ! -x "$start_bin" ]]; then
    echo "[tor-browser-desktop] ERROR: Tor Browser launcher not found or not executable at: ${start_bin}" >&2
    exit 1
  fi

  echo "Step 2: Extracting icons into /usr/share/icons/hicolor..."
  local icon_src_dir="${install_dir}/Browser/browser/chrome/icons/default"
  local icon_png_abs="${icon_src_dir}/default128.png"

  if [[ ! -d "$icon_src_dir" ]]; then
    echo "[tor-browser-desktop] WARN: icon source directory not found: ${icon_src_dir}" >&2
  else
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

  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    echo "Step 3: Updating icon cache..."
    gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
  else
    echo "Step 3: Skipping icon cache update (gtk-update-icon-cache not installed)..."
  fi

  echo "Step 4: Installing system desktop entry..."
  local desktop_path="/usr/share/applications/${desktop_id}.desktop"

  # Prefer the absolute PNG to guarantee correctness even if icon theme/caches are odd.
  local icon_field="$icon_name"
  if [[ -f "$icon_png_abs" ]]; then
    icon_field="$icon_png_abs"
  fi

  cat >"$desktop_path" <<EOF
[Desktop Entry]
Type=Application
Name=${app_name}
Comment=Browse the web anonymously
Exec=${start_bin} --detach
Path=${install_dir}
Icon=${icon_field}
Categories=${categories}
Terminal=false
StartupNotify=true
# WM_CLASS varies; leaving it out avoids "click does nothing" when mismatched.
EOF

  # IMPORTANT: must be executable or XFCE will prompt "Run / Display?"
  chmod 0755 "$desktop_path"

  echo "Step 5: Installing Desktop shortcut..."
  local d_uid="${TORBROWSER_DESKTOP_UID:-1000}"
  local d_gid="${TORBROWSER_DESKTOP_GID:-1000}"
  local d_home="${TORBROWSER_DESKTOP_HOME:-}"
  local d_name="${TORBROWSER_DESKTOP_FILENAME:-Tor Browser.desktop}"

  if [[ -z "${d_home:-}" ]]; then
    d_home="$(detect_home_for_uid "$d_uid")"
  fi

  local desktop_dir="${d_home}/Desktop"
  local desktop_shortcut="${desktop_dir}/${d_name}"

  install -m 0755 -d "$desktop_dir"
  install -m 0644 "$desktop_path" "$desktop_shortcut"

  # IMPORTANT: Desktop shortcut copy must also be executable to avoid prompt
  chmod 0755 "$desktop_shortcut"

  chown "$d_uid:$d_gid" "$desktop_dir" "$desktop_shortcut"

  echo "Step 6: Desktop integration complete."
  log "System desktop entry: ${desktop_path}"
  log "Desktop shortcut:     ${desktop_shortcut}"
  log "Launcher:            ${start_bin}"
  log "Icon:                ${icon_field}"
}

main "$@"
