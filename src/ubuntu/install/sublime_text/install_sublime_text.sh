# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing Sublime Text ======="

# Install Sublime Text
echo "Step 1: Downloading GPG key and adding apt list..."
apt-get update
apt-get install -y apt-transport-https
wget -qO /tmp/sublimehq-pub.asc https://download.sublimetext.com/sublimehq-pub.gpg --no-check-certificate
apt-key add /tmp/sublimehq-pub.asc
echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | tee /etc/apt/sources.list.d/sublime-text.sources

echo "Step 2: Finally installing the app..."
apt-get update
apt-get install -y sublime-text

# Desktop icon
echo "Step 3: Modify the desktop icon..."
cp /usr/share/applications/sublime_text.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/sublime_text.desktop

# Cleanup for app layer
echo "Step 4: Cleaning up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

echo "Sublime Text is now installed!"