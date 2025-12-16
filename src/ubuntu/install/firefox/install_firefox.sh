#!/usr/bin/env bash
# This script is meant to install Firefox browser and to be called from a Dockerfile.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Install Firefox ======="

. /etc/os-release
ARCH="$(dpkg --print-architecture)"

apt_update_if_needed
apt_install gnupg

if [ "${ID}" = "ubuntu" ]; then
  echo "Ubuntu detected: installing Firefox from Mozilla APT repo (non-snap)."

  KEYRING_PATH="/etc/apt/keyrings/mozilla.gpg"
  LIST_FILE="/etc/apt/sources.list.d/mozilla-firefox.list"
  PREF_FILE="/etc/apt/preferences.d/mozilla-firefox"

  install -m 0755 -d /etc/apt/keyrings

  wget -qO /tmp/mozilla.gpg https://packages.mozilla.org/apt/repo-signing-key.gpg
  gpg --dearmor -o "${KEYRING_PATH}" /tmp/mozilla.gpg
  rm -f /tmp/mozilla.gpg
  chmod a+r "${KEYRING_PATH}"

  cat >"${LIST_FILE}" <<EOF
deb [signed-by=${KEYRING_PATH}] https://packages.mozilla.org/apt mozilla main
EOF

  # Pin only Firefox packages, not Package: *
  cat >"${PREF_FILE}" <<'EOF'
Package: firefox*
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

  apt_refresh_after_repo_change
  apt_install firefox

else
  echo "${ID} detected: installing Firefox ESR from distro repos."
  apt_install firefox-esr
fi

echo "Firefox version installed:"
(firefox --version || firefox-esr --version) || true

# Optional: create a default profile for the Kasm user home
echo "Creating default profile..."
mkdir -p "$HOME/.mozilla/firefox"

# Use whichever binary exists
FF_BIN=""
if command -v firefox >/dev/null 2>&1; then
  FF_BIN="firefox"
elif command -v firefox-esr >/dev/null 2>&1; then
  FF_BIN="firefox-esr"
fi

if [ -n "$FF_BIN" ]; then
  "$FF_BIN" -headless -CreateProfile "kasm $HOME/.mozilla/firefox/kasm" || true
fi

# Desktop shortcut (if available)
mkdir -p "$HOME/Desktop"
if [ -f /usr/share/applications/firefox.desktop ]; then
  cp /usr/share/applications/firefox.desktop "$HOME/Desktop/firefox.desktop"
elif [ -f /usr/share/applications/firefox-esr.desktop ]; then
  cp /usr/share/applications/firefox-esr.desktop "$HOME/Desktop/firefox.desktop"
fi

chmod +x "$HOME/Desktop/firefox.desktop" 2>/dev/null || true
chown 1000:1000 "$HOME/Desktop/firefox.desktop" 2>/dev/null || true

echo "Firefox installed!"
