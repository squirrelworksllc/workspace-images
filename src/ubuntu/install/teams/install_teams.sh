# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Install Microsoft Teams (teams-for-linux) ======="
echo "Step 1: Install dependencies and add teams-for-linux repo..."

# 1) Dependencies
apt-get update
apt-get install -y wget gnupg ca-certificates

# 2) Repo key + sources (Debian/Ubuntu, amd64)
mkdir -p /etc/apt/keyrings
wget -qO /etc/apt/keyrings/teams-for-linux.asc https://repo.teamsforlinux.de/teams-for-linux.asc

cat <<'EOF' | tee /etc/apt/sources.list.d/teams-for-linux-packages.sources > /dev/null
Types: deb
URIs: https://repo.teamsforlinux.de/debian/
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/teams-for-linux.asc
Architectures: amd64
EOF

# 3) Install latest teams-for-linux .deb via APT
apt-get update
apt-get install -y teams-for-linux

echo "Step 2: Basic config and desktop shortcut..."

# Create config dir (if you want to drop defaults later)
mkdir -p "$HOME/.config/teams-for-linux"

# Desktop file setup (if present)
DESKTOP_FILE="/usr/share/applications/teams-for-linux.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  mkdir -p "$HOME/Desktop"
  cp "$DESKTOP_FILE" "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/teams-for-linux.desktop"
fi

echo "Step 3: Optional cleanup..."

if [ -z "${SKIP_CLEAN+x}" ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

# App-layer cleanup (only do this if you're in a container image!)
chown -R 1000:0 "$HOME" || true
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \; || true

echo "teams-for-linux (Microsoft Teams client) is now installed!"