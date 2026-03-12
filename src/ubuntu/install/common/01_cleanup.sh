#!/usr/bin/env bash
###############################################################################
# 01_cleanup.sh
# Purpose: Final build-time cleanup for SquirrelWorks 1.1 images.
###############################################################################
set -euo pipefail

log() { echo "[CLEANUP] $*"; }

main() {
    log "======= Running Final Image Optimization ======="

    : "${SKIP_CLEAN:=false}"
    if [ "${SKIP_CLEAN}" = "true" ]; then
        log "SKIP_CLEAN=true; skipping optimization."
        exit 0
    fi

    # Step 1: APT Purge
    log "Step 1: Deep-cleaning APT and package metadata..."
    apt-get autoremove -y
    apt-get autoclean -y
    apt-get clean

    # Step 2: Cache & Temp Cleanup
    log "Step 2: Clearing temporary files and user caches..."
    # Noble fix: wipe the newer font and icon caches created during installs
    rm -rf /root/.cache /root/.dbus /root/.local/share/keyrings
    rm -rf /home/kasm-default-profile/.cache /home/kasm-user/.cache
    
    # Recreate /tmp with standard sticky-bit permissions
    rm -rf /tmp/* /var/tmp/*
    find /var/log -type f -exec truncate -s 0 {} \;

    # Step 3: Global Autostart Suppression
    # We remove these so the Kasm session doesn't try to launch 
    # desktop services that don't make sense in a container.
    log "Step 3: Suppressing unwanted XDG autostart services..."
    AUTOSTART_DIR="/etc/xdg/autostart"
    SERVICES=(
        "blueman.desktop" "geoclue-demo-agent.desktop" "gnome-keyring-pkcs11.desktop"
        "gnome-keyring-secrets.desktop" "gnome-keyring-ssh.desktop" "pulseaudio.desktop"
        "xfce4-power-manager.desktop" "xfce4-screensaver.desktop" "light-locker.desktop"
        "org.gnome.Evolution-alarm-notify.desktop" "org.gnome.SettingsDaemon.Power.desktop"
    )

    for svc in "${SERVICES[@]}"; do
        rm -f "${AUTOSTART_DIR}/${svc}" 2>/dev/null || true
    done

    # Step 4: Icon & Localization Slimming
    log "Step 4: Cleaning up localized manual pages and icon caches..."
    find /usr/share/doc -type f -not -name 'copyright' -delete 2>/dev/null || true
    find /usr/share/man -type f -name "*.gz" -delete 2>/dev/null || true
    find /usr/share -name "icon-theme.cache" -type f -delete 2>/dev/null || true

    # Step 5: Final Ownership Sync
    log "Step 5: Synchronizing home directory permissions..."
    # Ensure all config files are owned by the Kasm user
    for home in "/home/kasm-user" "/home/kasm-default-profile"; do
        if [ -d "$home" ]; then
            chown -R 1000:0 "$home" 2>/dev/null || true
        fi
    done

    # Security: Clear bash history from the build process
    rm -f /root/.bash_history /home/kasm-default-profile/.bash_history

    log "Cleanup complete. Image is ready for production."
}

main "$@"
