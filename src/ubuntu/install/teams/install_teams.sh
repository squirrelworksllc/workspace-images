# This script installs Microsoft Teams. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Install Microsoft Teams (teams-for-linux) ======="

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  echo "teams-for-linux repo is amd64-only; skipping on ${ARCH}."
  exit 0
fi

. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) ;;
  *)
    echo "Unsupported distro for teams-for-linux installer: ${ID}" >&2
    exit 1
    ;;
esac

echo "Step 1: Install deps..."
apt_update_if_needed
apt_install wget gnupg ca-certificates

echo "Step 2: Add teams-for-linux repo..."
install -m 0755 -d /etc/apt/keyrings
wget -qO /etc/apt/keyrings/teams-for-linux.asc https://repo.teamsforlinux.de/teams-for-linux.asc
chmod a+r /etc/apt/keyrings/teams-for-linux.asc

cat >/etc/apt/sources.list.d/teams-for-linux-packages.sources <<'EOF'
Types: deb
URIs: https://repo.teamsforlinux.de/debian/
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/teams-for-linux.asc
Architectures: amd64
EOF

apt_refresh_after_repo_change

echo "Step 3: Install teams-for-linux..."
apt_install teams-for-linux

echo "Step 4: Desktop shortcut..."
mkdir -p "$HOME/Desktop" "$HOME/.config/teams-for-linux"

DESKTOP_FILE="/usr/share/applications/teams-for-linux.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  cp "$DESKTOP_FILE" "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/teams-for-linux.desktop"
  chown 1000:1000 "$HOME/Desktop/teams-for-linux.desktop" 2>/dev/null || true
fi

echo "teams-for-linux installed!"