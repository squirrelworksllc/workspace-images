# This is the cleanup script that runs following app installs.
#!/usr/bin/env bash
set -euo pipefail
set -x

echo "======= Running Final Cleanups ======="

: "${SKIP_CLEAN:=false}"

. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) echo "Detected distro: ${ID}" ;;
  *) echo "Unsupported distro for this cleanup script: ${ID}" >&2; exit 1 ;;
esac

if [ "${SKIP_CLEAN}" = "true" ]; then
  echo "SKIP_CLEAN=true; skipping final cleanup."
  exit 0
fi

echo "Step 1: Distro package cleanup..."
apt-get autoremove -y
apt-get autoclean -y
apt-get clean

echo "Step 2: File cleanup..."
rm -rf /root/.cache || true
rm -rf \
  /home/kasm-default-profile/.cache \
  /home/kasm-user/.cache \
  /var/lib/apt/lists/* \
  /var/tmp/*

rm -rf /tmp/*
mkdir -p /tmp
chmod 1777 /tmp

echo "Step 2b: Remove icon caches..."
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \; || true

echo "Step 3: Services cleanup..."
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
  /etc/xdg/autostart/xscreensaver.desktop

echo "Step 4: Bins cleanup..."
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  rm -f "$(command -v gnome-keyring-daemon)"
fi

echo "Step 5: Ownership fix..."
chown -R 1000:0 /home/kasm-user/.config /home/kasm-user/Desktop 2>/dev/null || true
chown -R 1000:0 /home/kasm-default-profile/.config /home/kasm-default-profile/Desktop 2>/dev/null || true

echo "Cleanup is complete!"