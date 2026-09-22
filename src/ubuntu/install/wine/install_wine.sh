#!/usr/bin/env bash
###############################################################################
# install_wine.sh
# Purpose: Installs WineHQ Staging for Kasm 1.18+ (Noble/Debian)
###############################################################################
set -euo pipefail
LOG_TAG="WINE-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
  log "======= Installing WineHQ Staging ======="

  # 1. Architecture Check & Setup
  local arch
  arch="$(dpkg --print-architecture)"
  if [ "$arch" = "amd64" ]; then
    log "Enabling i386 architecture for 32-bit Windows app support..."
    dpkg --add-architecture i386
  fi

  apt_update_if_needed

  # 2. Keyring & Repo Setup
  . /etc/os-release
  local suite="${VERSION_CODENAME}"
  
  log "Adding WineHQ repository for ${suite}..."
  mkdir -p /etc/apt/keyrings
  wget -qO - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key

  cat <<EOF > /etc/apt/sources.list.d/winehq.sources
Types: deb
URIs: https://dl.winehq.org/wine-builds/ubuntu
Suites: ${suite}
Components: main
Architectures: amd64 i386
Signed-By: /etc/apt/keyrings/winehq-archive.key
EOF

  apt_refresh_after_repo_change

  # 3. Installation
  # We use staging as per REMnux preference for malware analysis tools
  log "Installing winehq-staging (this may take a while)..."
  apt_install --install-recommends winehq-staging

  # 4. Pre-caching Wine-Mono and Wine-Gecko
  log "Pre-caching Wine-Mono and Wine-Gecko to skip first-run prompts..."
  WINE_CACHE_DIR="/usr/share/wine/gecko"
  mkdir -p "$WINE_CACHE_DIR"
  WINE_MONO_DIR="/usr/share/wine/mono"
  mkdir -p "$WINE_MONO_DIR"

  # We pull the specific versions that WineHQ Staging 9.x+ (Noble era) expects
  # Note: These URLs are stable, but we use -L to follow redirects.
  curl -fL "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi" -o "$WINE_CACHE_DIR/wine-gecko-2.47.4-x86_64.msi"
  curl -fL "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86.msi" -o "$WINE_CACHE_DIR/wine-gecko-2.47.4-x86.msi"
  curl -fL "https://dl.winehq.org/wine/wine-mono/9.1.0/wine-mono-9.1.0-x86.msi" -o "$WINE_MONO_DIR/wine-mono-9.1.0-x86.msi"

  # 5. Install Winetricks
  log "Installing Winetricks for manual dependency management..."
  wget -qO /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
  chmod +x /usr/local/bin/winetricks
  
  # Install cabextract (Required by winetricks to unpack many Windows components)
  apt_install cabextract

  log "Wine dependencies pre-cached."

  # 6. Trigger UI & Environment Cleanup
  run_configure_ui

  log "Cleaning up WineHQ repository files to prevent conflicts with REMnux installer..."
  rm -f /etc/apt/sources.list.d/winehq.sources
  rm -f /etc/apt/keyrings/winehq-archive.key

  log "Wine installation complete."
}

main "$@"
