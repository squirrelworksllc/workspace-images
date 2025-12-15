# This is the cleanup script that runs following app installs.
# It should only be called at the END of the dockerfile after all apps are installed!
#!/usr/bin/env bash
set -euo pipefail

echo "======= Running Final Cleanups ======="

: "${SKIP_CLEAN:=false}"

if [ "${SKIP_CLEAN}" = "true" ]; then
  echo "SKIP_CLEAN=true; skipping final cleanup."
  exit 0
fi

# Sanity: only intended for Debian-family images
. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) echo "Detected distro: ${ID}" ;;
  *)
    echo "Unsupported distro for this cleanup script: ${ID}" >&2
    exit 1
    ;;
esac

echo "Step 1: APT package cleanup..."
# Keep these non-fatal; some base layers can be picky
apt-get autoremove -y || true
apt-get autoclean -y || true
apt-get clean || true

echo "Step 2: Cache + temp cleanup..."
rm -rf /root/.cache 2>/dev/null || true
rm -rf /home/kasm-default-profile/.cache 2>/dev/null || true
rm -rf /home/kasm-user/.cache 2>/dev/null || true

# Remove apt lists + temp dirs to shrink image
rm -rf /var/lib/apt/lists/* /var/tmp/* 2>/dev/null || true

# Recreate /tmp safely with correct perms
rm -rf /tmp 2>/dev/null || true
install -d -m 1777 /tmp

echo "Step 2b: Remove icon theme caches..."
find /usr/share -name "icon-theme.cache" -type f -delete 2>/dev/null || true

echo "Step 3: Disable unwanted autostarts..."
rm -f \
  /etc/xdg/autostart/blueman.desktop \
  /etc/xdg/autostart/geoclue-demo-agent.desktop \
  /etc/xdg/autostart/gnome-keyring-pkcs11.desktop \
  /etc/xdg/autostart/gnome-keyring-secrets.desktop \
  /etc/xdg/autostart/gnome-keyring-ssh.desktop \
  /etc/xdg/autostart/gnome-shell-overrides-migration.desktop \
  /etc/xdg/autostart/light-locker.desktop \
  /etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.A11ySettings.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Color.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Datetime.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Housekeeping.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Keyboard.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.MediaKeys.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Power.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.PrintNotifications.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Rfkill.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.ScreensaverProxy.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Sharing.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Smartcard.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Sound.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.UsbProtection.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Wacom.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.Wwan.desktop \
  /etc/xdg/autostart/org.gnome.SettingsDaemon.XSettings.desktop \
  /etc/xdg/autostart/pulseaudio.desktop \
  /etc/xdg/autostart/xfce4-power-manager.desktop \
  /etc/xdg/autostart/xfce4-screensaver.desktop \
  /etc/xdg/autostart/xfce-polkit.desktop \
  /etc/xdg/autostart/xscreensaver.desktop \
  2>/dev/null || true

echo "Step 4: Remove unwanted binaries..."
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  rm -f "$(command -v gnome-keyring-daemon)" || true
fi

echo "Step 5: Ownership fix (best effort)..."
chown -R 1000:0 /home/kasm-user/.config /home/kasm-user/Desktop 2>/dev/null || true
chown -R 1000:0 /home/kasm-default-profile/.config /home/kasm-default-profile/Desktop 2>/dev/null || true

echo "Cleanup is complete!"