# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing Discord ======="

echo "Step 1: Install the app..."
# Make sure curl exists
apt-get update
apt-get install -y curl
# Install Discord from deb
curl -L -o /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
apt-get install -y /tmp/discord.deb
rm /tmp/discord.deb

# Default config values
echo "Step 2: Set config values..."
mkdir -p "$HOME/.config/discord"
echo '{"SKIP_HOST_UPDATE": true}' > "$HOME/.config/discord/settings.json"

# Desktop file setup (only if it exists)
echo "Step 3: Fix Desktop files..."
DESKTOP_FILE="/usr/share/applications/discord.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    sed -i 's@Exec=/usr/share/discord/Discord@Exec=/usr/share/discord/Discord --no-sandbox@g' "$DESKTOP_FILE"

    mkdir -p "$HOME/Desktop"
    cp "$DESKTOP_FILE" "$HOME/Desktop/"
    chmod +x "$HOME/Desktop/discord.desktop"
fi

# Cleanup
echo "Step 4: Cleaning up..."
if [ -z "${SKIP_CLEAN+x}" ]; then
    apt-get autoclean
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*
fi

# Cleanup for app layer (be careful with this outside containers)
chown -R 1000:0 "$HOME"
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

echo "Discord is now installed!"