#!/usr/bin/env bash
###############################################################################
# packages.sh
#
# The plain "apt-get install" slice of BitCurator 5's package set, flattened
# from bitcurator-salt's bitcurator/packages/*.sls (each upstream file is
# just `pkgname:\n  pkg.installed`, one apt package per state - see
# vendor/NOTICE.md for where this list comes from and why it's reimplemented
# here instead of run through Salt).
#
# Excluded on purpose (meaningless or actively wrong in a Kasm container):
#   dkms, linux-headers-generic  - build kernel modules against a running
#                                  kernel; there isn't one to build against.
#   docker (docker-ce)           - Kasm has its own dedicated DinD image;
#                                  this desktop image doesn't run dockerd.
#   mokutil                      - UEFI Secure Boot key management.
#   plymouth-themes, plymouth-x11 - boot splash theming; no bootloader here.
#   open-vm-tools-desktop        - VMware guest integration.
#   libappindicator1, nautilus-script-audio-convert - upstream's own .sls
#     already skips these on oscodename == noble (not packaged for Noble).
#
# Renamed for Noble (Ubuntu 24.04 rebuilt several libs with a "t64" ABI
# suffix for the 64-bit time_t transition; upstream's .sls branches on
# oscodename to pick the right name - we only ever build for Noble):
#   libcrypto++8 -> libcrypto++8t64, libdvdread8 -> libdvdread8t64,
#   libvte9 -> libvte9t64, libqt5*5 -> libqt5*5t64 (guymager's Qt5 libs).
#
# Installed in batches rather than one giant list: apt-get install fails
# the WHOLE command atomically if any single package name is wrong for this
# Ubuntu release, and with ~140 packages sourced from another project's
# release notes some drift is inevitable. Each batch is independent and
# best-effort (matches the tolerance the old bitcurator-cli/Salt run had),
# so one bad/renamed package only costs its own batch, not the whole build.
# The final sanity check in install_bitcurator5.sh catches anything that
# silently failed to land.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[BITCURATOR-PACKAGES] $*"; }

install_batch() {
  apt_install "$@" || log "WARNING: one or more of [$*] failed to install - continuing."
}

main() {
  log "======= Installing BitCurator forensics/desktop packages ======="
  apt_update_if_needed

  # --- Repos needed before the batches below -----------------------------
  # Plain Ubuntu component repos (already signed by the distro's own key) -
  # not the keyed third-party add_apt_repo() helper common/03_scaffold.sh
  # provides for things like Mozilla's repo.
  enable_ubuntu_component() {
    apt_install software-properties-common
    add-apt-repository -y "$1" || true
  }
  enable_ubuntu_component "universe"
  enable_ubuntu_component "multiverse"
  apt_refresh_after_repo_change

  # --- Disk/image format tools --------------------------------------------
  install_batch xmount afflib-tools ewf-tools libewf2 libewf-dev libbde-utils \
    libvhdi-dev libvmdk-dev libvshadow-utils vmfs-tools xfsprogs hfsplus \
    hfsprogs hfsutils hfsutils-tcltk ntfs-3g qemu-utils squashfs-tools \
    mtd-utils avfs disktype bchunk cdrdao icedax syslinux-utils sleuthkit \
    testdisk gddrescue dcfldd dvdisaster nwipe zerofree hdparm smartmontools \
    cryptsetup lvm2 udisks2 fdutils

  # --- Archival / conversion / media ---------------------------------------
  install_batch antiword pst-utils libimage-exiftool-perl mediainfo ffmpeg \
    libavcodec-extra mencoder mplayer vlc brasero clonezilla xorriso \
    sharutils ccrypt hashdeep hashrat ssdeep tree gawk dialog yad ghex \
    gtkhash gparted grsync hardinfo discover mate-utils

  # --- Antivirus / security -------------------------------------------------
  install_batch clamav clamav-daemon clamtk

  # --- Guymager (Noble's Qt5 libs carry the t64 ABI suffix) -----------------
  install_batch libqt5core5t64 libqt5dbus5t64 libqt5gui5t64 libqt5widgets5t64
  install_batch guymager

  # --- Build toolchain (also used directly by build_tools.sh) --------------
  install_batch build-essential cmake g++ make bison flex swig pkg-config \
    libtool libtool-bin dh-autoreconf equivs git curl expat expect gawk \
    software-properties-common libarchive-dev

  # --- Dev libraries pulled in for the forensics tool builds ---------------
  install_batch libssl-dev libbz2-dev libcurl4-openssl-dev libevent-dev \
    libexif-dev libfuse-dev libjpeg-dev libmad0 libmagic-dev \
    libmysqlclient-dev libncurses-dev libnss-myhostname \
    libparse-win32registry-perl libpthread-stubs0-dev libreadline-dev \
    libsodium23 libsodium-dev libsqlite3-dev libtalloc-dev libtre-dev \
    libtre5 libudev-dev libusb-dev libvte-common libvte9t64 libxml2-dev \
    libxml2-utils libxslt1-dev libafflib-dev libguestfs-tools uuid-dev \
    unixodbc unixodbc-dev zlib1g-dev libre2-dev pcre2-utils \
    libappindicator3-1 libappindicator3-dev gir1.2-appindicator3-0.1

  # --- Noble-renamed (t64 ABI) singles -------------------------------------
  install_batch libcrypto++8t64 libdvdread8t64

  # --- Python (system) -------------------------------------------------------
  install_batch python3 python3-dev python3-numpy python3-pip \
    python3-pyqt5 python3-setuptools python3-sip-dev python3-tk \
    python3-testresources python3-virtualenv python3-tsk
  install_batch libicu-dev
  install_batch python3-icu

  # --- Networking / system ---------------------------------------------------
  # openssh-server deliberately excluded (upstream installs it for bare-metal
  # remote access; a Kasm session is already reached over the web UI, and
  # baking sshd + static host keys into a shared image is an unnecessary
  # attack surface).
  install_batch openssh-client cifs-utils dbus-x11 dconf-cli \
    dconf-editor xdg-utils mysql-client sudo

  # --- Nautilus/file-manager scripts support (harmless if Thunar is the
  # actual file manager in use - see desktop_integration.sh for the Thunar
  # custom-actions equivalent) -----------------------------------------------
  install_batch nautilus-scripts-manager

  log "Package batches complete."
}

main "$@"
