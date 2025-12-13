# Customized script to install Thunderbird email client using the DEB package instead of snap
#!/usr/bin/env bash
set -ex

echo "======= Installing Thunderbird (DEB, no snap) ======="

# Make sure we have needed tools
apt-get update
apt-get install -y software-properties-common

# Remove any existing Thunderbird, the wrapper and set the PPA
echo "Step 1: Setting up the environment..."
# Remove snap version if present (ignore errors)
snap remove --purge thunderbird 2>/dev/null || true
# Remove Ubuntu's transitional deb wrapper, if installed
apt-get remove -y thunderbird || true

# Add Mozilla Team PPA
add-apt-repository -y ppa:mozillateam/ppa
# Set APT pinning so we prefer the PPA and avoid the snap wrapper
cat >/etc/apt/preferences.d/thunderbird <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: thunderbird
Pin: version 2:1snap*
Pin-Priority: -1
EOF

# Update APT and install Thunderbird from PPA
echo "Step 2: Installing the app..."
apt-get update
apt-get install -y thunderbird

# Fix the desktop icon
echo "Step 3: Fixing the Desktop icon..."
cp /usr/share/applications/thunderbird.desktop "$HOME/Desktop/" || true
chmod +x "$HOME/Desktop/thunderbird.desktop" || true

# Finally clean up
echo "Step 5: Cleanup..."
chown -R 1000:0 "$HOME" || true
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \; || true

echo "Thunderbird is now Installed (DEB, no snap)!"