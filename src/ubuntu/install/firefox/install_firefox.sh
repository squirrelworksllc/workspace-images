# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -xe

# Helper to strip any stray CR characters (in case of CRLF line endings)
clean() { printf '%s' "$1" | tr -d '\r'; }

echo "======= Install Firefox ======="
echo "Step 1: Install dependencies and configure Mozilla repo..."

# 1) Dependencies
apt-get update
apt-get install -y wget gnupg ca-certificates

# 2) Paths (sanitized to avoid trailing \r)
KEYRING_PATH=$(clean "/usr/share/keyrings/mozilla-archive-keyring.gpg")
LIST_FILE=$(clean "/etc/apt/sources.list.d/mozilla-firefox.list")
PREF_FILE=$(clean "/etc/apt/preferences.d/mozilla-firefox")

# 3) Download and dearmor GPG key
mkdir -p /usr/share/keyrings
wget -qO /tmp/mozilla.gpg https://packages.mozilla.org/apt/repo-signing-key.gpg
gpg --dearmor -o "$KEYRING_PATH" /tmp/mozilla.gpg
rm /tmp/mozilla.gpg

# 4) Add Mozilla Firefox APT repo
echo "deb [signed-by=$KEYRING_PATH] https://packages.mozilla.org/apt mozilla main" | \
  tee "$LIST_FILE" > /dev/null

# 5) Pin Mozilla repo so its Firefox wins over Ubuntu's
cat <<EOF | tee "$PREF_FILE" > /dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

# 6) Install Firefox
apt-get update
apt-get install -y firefox

# 7) Print the Firefox version JUST to be sure
echo "Firefox version installed:"
firefox --version || true

echo "Step 2: Create the Static Default profile..."
if grep -q "ID=debian" /etc/os-release || grep -q "ID=parrot" /etc/os-release; then
  if [ "${ARCH}" = "amd64" ]; then
    preferences_file=/usr/lib/firefox/defaults/pref/firefox.js
  else
    preferences_file=/usr/lib/firefox-esr/defaults/pref/firefox.js
  fi
else # else if any other Debian/Ubuntu variant
  preferences_file=/usr/lib/firefox/browser/defaults/preferences/firefox.js
fi

chown -R 0:0 "$HOME"
firefox -headless -CreateProfile "kasm $HOME/.mozilla/firefox/kasm"

echo "Step 3: Finalize some Customizations..."
# Starting with version 67, Firefox creates a unique profile mapping per installation which is hash generated
#   based off the installation path. Because that path will be static for our deployments we can assume the hash
#   and thus assign our profile to the default for the installation

# if Kali
if grep -q "ID=kali" /etc/os-release; then
  cat >>"$HOME/.mozilla/firefox/profiles.ini" <<EOL
[Install3B6073811A6ABF12]
Default=kasm
Locked=1
EOL

# if Debian OR ParrotOS
elif grep -q "ID=debian" /etc/os-release || grep -q "ID=parrot" /etc/os-release; then
  if [ "${ARCH}" != "amd64" ]; then
    cat >>"$HOME/.mozilla/firefox/profiles.ini" <<EOL
[Install3B6073811A6ABF12]
Default=kasm
Locked=1
EOL
  else
    cat >>"$HOME/.mozilla/firefox/profiles.ini" <<EOL
[Install4F96D1932A9F858E]
Default=kasm
Locked=1
EOL
  fi
fi

# Cleanup for app layer
echo "Step 4: Cleaning Up..."
chown -R 1000:0 "$HOME"
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

if [ -f "$HOME/Desktop/firefox.desktop" ]; then
  chmod +x "$HOME/Desktop/firefox.desktop"
fi

chown -R 1000:1000 "$HOME/.mozilla"

echo "Firefox is now installed!"