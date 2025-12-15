# This script installs Signal. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Signal ======="

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  echo "Signal Desktop repo is amd64-only; skipping on ${ARCH}."
  exit 0
fi

. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) ;;
  *)
    echo "Unsupported distro for Signal installer: ${ID}" >&2
    exit 1
    ;;
esac

echo "Step 1: Install deps..."
apt_update_if_needed
apt_install wget ca-certificates gnupg

echo "Step 2: Add Signal APT repo (xenial suite, supported by Signal)..."
install -m 0755 -d /etc/apt/keyrings
wget -qO /etc/apt/keyrings/signal.gpg https://updates.signal.org/desktop/apt/keys.asc
chmod a+r /etc/apt/keyrings/signal.gpg

cat >/etc/apt/sources.list.d/signal-xenial.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/signal.gpg] https://updates.signal.org/desktop/apt xenial main
EOF

apt_refresh_after_repo_change

echo "Step 3: Install signal-desktop..."
apt_install signal-desktop

echo "Step 4: Desktop shortcut..."
mkdir -p "$HOME/Desktop"

DESKTOP_FILE="/usr/share/applications/signal-desktop.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  # Add --no-sandbox (best-effort; don’t fail if upstream changes Exec line)
  sed -i 's|^Exec=/opt/Signal/signal-desktop %U|Exec=/opt/Signal/signal-desktop --no-sandbox %U|' "$DESKTOP_FILE" || true

  cp "$DESKTOP_FILE" "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/signal-desktop.desktop"
  chown 1000:1000 "$HOME/Desktop/signal-desktop.desktop" 2>/dev/null || true
fi

echo "Signal installed!"