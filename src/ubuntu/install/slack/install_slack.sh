# This script installs Slack. It is meant to be called from a Dockerfile
# and installed on Ubuntu and/or a debian variant.
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Slack ======="

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  echo "Slack .deb is amd64-only; skipping on ${ARCH}."
  exit 0
fi

apt_update_if_needed
# wget/curl should already exist from install_tools, but this is safe if not:
# apt_install wget ca-certificates

echo "Downloading Slack..."
wget -qO /tmp/slack.deb https://downloads.slack-edge.com/linux_releases/slack-desktop-latest-amd64.deb

echo "Installing Slack..."
apt-get install -y /tmp/slack.deb
rm -f /tmp/slack.deb

echo "Desktop shortcut..."
mkdir -p "$HOME/Desktop"

DESKTOP_FILE="/usr/share/applications/slack.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  # Add --no-sandbox (best-effort)
  sed -i 's@^Exec=/usr/bin/slack@Exec=/usr/bin/slack --no-sandbox@' "$DESKTOP_FILE" || true

  cp "$DESKTOP_FILE" "$HOME/Desktop/slack.desktop"
  chmod +x "$HOME/Desktop/slack.desktop"
  chown 1000:1000 "$HOME/Desktop/slack.desktop" 2>/dev/null || true
fi

echo "Slack installed!"