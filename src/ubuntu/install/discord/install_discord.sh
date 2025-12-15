# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -euo pipefail
source /dockerstartup/install/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing Discord ======="

echo "Step 1: Install the app..."
apt_update_if_needed
apt_install curl ca-certificates

curl -fsSL -o /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
apt-get install -y /tmp/discord.deb
rm -f /tmp/discord.deb

echo "Step 2: Set config values..."
mkdir -p "$HOME/.config/discord"
cat >"$HOME/.config/discord/settings.json" <<'JSON'
{"SKIP_HOST_UPDATE": true}
JSON

echo "Step 3: Fix Desktop files..."
DESKTOP_FILE="/usr/share/applications/discord.desktop"
if [ -f "$DESKTOP_FILE" ]; then
  sed -i 's@^Exec=/usr/share/discord/Discord@Exec=/usr/share/discord/Discord --no-sandbox@g' "$DESKTOP_FILE"

  mkdir -p "$HOME/Desktop"
  cp "$DESKTOP_FILE" "$HOME/Desktop/discord.desktop"
  chmod +x "$HOME/Desktop/discord.desktop"
  chown 1000:1000 "$HOME/Desktop/discord.desktop" || true
fi

echo "Step 4: Cleaning up..."
apt_cleanup

echo "Discord is now installed!"