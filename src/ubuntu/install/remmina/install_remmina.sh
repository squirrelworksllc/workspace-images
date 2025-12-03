# Copied from official KasmTech repo at "https://github.com/kasmtech/workspaces-images/blob/develop/src/ubuntu/install/"
# Modified to remove non-ubuntu references and apply updated logic
#!/usr/bin/env bash
set -ex

echo "======= Installing Remmina ======="






echo "Step 1: Install the app..."
# If this is Ubuntu Noble...
if grep -q "ID=debian" /etc/os-release || grep -q "VERSION_CODENAME=noble" /etc/os-release; then
  apt-get update
  apt-get install -y remmina remmina-plugin-rdp remmina-plugin-secret xdotool
  if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
  fi
else # If this is another Ubuntu version...
  apt-get update
  apt-get install -y software-properties-common
  apt-add-repository -y ppa:remmina-ppa-team/remmina-next
  apt-get update
  apt-get install -y remmina remmina-plugin-rdp remmina-plugin-secret remmina-plugin-spice xdotool
  if [ -z ${SKIP_CLEAN+x} ]; then
  apt-get autoclean
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/*
  fi
fi

echo "Step 2: Adjust the desktop icon..."
cp /usr/share/applications/org.remmina.Remmina.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/org.remmina.Remmina.desktop
chown 1000:1000 $HOME/Desktop/org.remmina.Remmina.desktop

echo "Step 3: Create user profile and directory..."
DEFAULT_PROFILE_DIR=$HOME/.local/share/remmina/defaults

mkdir -p $DEFAULT_PROFILE_DIR
# create the VNC profile
cat >>  $DEFAULT_PROFILE_DIR/default.vnc.remmina <<EOF
[remmina]
name=vnc-connection
proxy=
disableserverbell=0
showcursor=0
disablesmoothscrolling=0
enable-autostart=1
colordepth=32
ssh_tunnel_certfile=
server=
ssh_tunnel_enabled=0
postcommand=
group=
quality=9
disableencryption=0
username=
password=
ssh_tunnel_loopback=0
disablepasswordstoring=0
ssh_tunnel_passphrase=
viewmode=4
window_maximize=0
ssh_tunnel_password=
viewonly=0
notes_text=
ssh_tunnel_privatekey=
ssh_tunnel_username=
keymap=
window_height=480
ssh_tunnel_auth=0
precommand=
window_width=640
ssh_tunnel_server=
protocol=VNC
disableserverinput=0
ignore-tls-errors=1
disableclipboard=0
EOF
# create the RDP profile
cat >>  $DEFAULT_PROFILE_DIR/default.rdp.remmina <<EOF
[remmina]
disableclipboard=0
serialpath=
drive=
disable_fastpath=0
disablepasswordstoring=0
shareserial=0
password=
left-handed=0
parallelname=
gateway_password=
sharesmartcard=0
old-license=0
ssh_tunnel_loopback=0
shareprinter=0
resolution_height=0
group=
enable-autostart=0
ssh_tunnel_enabled=0
smartcardname=
gwtransp=http
domain=
serialname=
ssh_tunnel_auth=0
ssh_tunnel_server=
loadbalanceinfo=
ignore-tls-errors=1
clientname=
base-cred-for-gw=0
sound=off
freerdp_log_level=INFO
resolution_mode=2
ssh_tunnel_password=
protocol=RDP
relax-order-checks=0
gateway_username=
name=rdp-connection
usb=
preferipv6=0
dvc=
websockets=0
vc=
clientbuild=
postcommand=
restricted-admin=0
quality=0
username=
gateway_usage=0
security=
resolution_width=0
ssh_tunnel_privatekey=
rdp_reconnect_attempts=
console=0
microphone=
ssh_tunnel_passphrase=
gateway_server=
disableautoreconnect=0
ssh_tunnel_username=
glyph-cache=0
serialpermissive=0
network=none
ssh_tunnel_certfile=
execpath=
multitransport=0
rdp2tcp=
multimon=0
audio-output=
cert_ignore=0
exec=
monitorids=
span=0
pth=
freerdp_log_filters=
parallelpath=
notes_text=
printer_overrides=
timeout=
disable-smooth-scrolling=0
serialdriver=
precommand=
server=
useproxyenv=0
colordepth=99
gateway_domain=
shareparallel=0
viewmode=4
EOF

# Cleanup for app layer
echo "Step 4: Cleaning up..."
chown -R 1000:0 $HOME
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
chown -R 1000:1000 $DEFAULT_PROFILE_DIR

echo "Remmina is now Installed!"