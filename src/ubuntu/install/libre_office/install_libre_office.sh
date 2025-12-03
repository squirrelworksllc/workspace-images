# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing LibreOffice ======="
# Install LibreOffice
echo "Step 1: Installing the app..."
apt-get update
apt-get install -y software-properties-common
apt-get install -y libreoffice

# Desktop icon
echo "Step 2: Modify the desktop icon..."
sed -i "s@Exec=libreoffice@Exec=env LD_LIBRARY_PATH=:/usr/lib/libreoffice/program:/usr/lib/$(arch)-linux-gnu/ libreoffice@g" /usr/share/applications/libreoffice-*.desktop
cp /usr/share/applications/libreoffice-startcenter.desktop $HOME/Desktop/
chown 1000:1000 $HOME/Desktop/libreoffice-startcenter.desktop
chmod +x $HOME/Desktop/libreoffice-startcenter.desktop

# Cleanup for app layer
echo "Step 3: Cleaning up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*
fi

echo "LibreOffice is now installed!"