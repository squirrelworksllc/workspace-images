#!/usr/bin/env bash
###############################################################################
# build_tools.sh
#
# Forensics tools BitCurator installs from source or a pinned release
# artifact rather than apt, ported from bitcurator-salt's bitcurator/tools/
# and the source-build entries in bitcurator/packages/ (bulk-extractor,
# bulk-reviewer, lightgrep, siegfried). Versions/hashes are copied from
# upstream's .sls files as of bitcurator-salt VERSION 5.1.0 - see
# vendor/NOTICE.md.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[BITCURATOR-BUILD] $*"; }
try() { "$@" || log "WARNING: '$*' failed - continuing (best-effort build)."; }

build_bulk_extractor() {
  log "Building bulk_extractor v2.1.1..."
  apt_install build-essential libssl-dev flex libewf libewf-dev \
    libexpat1-dev libre2-dev libxml2-utils libtool pkg-config zlib1g-dev \
    make git
  rm -rf /usr/local/src/bulk_extractor
  git clone --branch v2.1.1 --recurse-submodules --depth 1 \
    https://github.com/simsong/bulk_extractor /usr/local/src/bulk_extractor
  ( cd /usr/local/src/bulk_extractor && ./bootstrap.sh && ./configure && make -s && make install -s )
  rm -rf /usr/local/src/bulk_extractor
}

build_lightgrep() {
  local version=1.5.0
  local hash=fe7aa3ed64472b6f57b5048b5584d3df2794507747e5d76213f60c256f8c82fa
  log "Building lightgrep ${version}..."
  apt_install build-essential git pkg-config dh-autoreconf libicu-dev \
    libboost-dev bison libboost-program-options-dev
  mkdir -p /usr/local/src/files
  curl -fsSL -o "/usr/local/src/files/lightgrep-${version}.tar.gz" \
    "https://github.com/strozfriedberg/lightgrep/releases/download/${version}/lightgrep-${version}.tar.gz"
  echo "${hash}  /usr/local/src/files/lightgrep-${version}.tar.gz" | sha256sum -c -
  rm -rf "/usr/local/src/lightgrep-${version}" /usr/local/src/lightgrep
  tar -xzf "/usr/local/src/files/lightgrep-${version}.tar.gz" -C /usr/local/src/
  mv "/usr/local/src/lightgrep-${version}" /usr/local/src/lightgrep
  ( cd /usr/local/src/lightgrep && autoreconf -fi && ./configure && make -j"$(nproc)" && make install && ldconfig )
  rm -rf /usr/local/src/lightgrep "/usr/local/src/files/lightgrep-${version}.tar.gz"
}

build_nsrllookup() {
  local hash=bdc17e38880f909eeaec60804db2276761c309279735eb42c781f6757edd4061
  log "Building nsrllookup 1.4.2..."
  apt_install build-essential cmake libboost-dev libboost-filesystem-dev \
    libboost-program-options-dev libboost-system-dev libboost-test-dev
  if command -v nsrllookup >/dev/null 2>&1; then
    log "nsrllookup already present - skipping."
    return 0
  fi
  curl -fsSL -o /tmp/nsrllookup-1.4.2.tar.gz \
    "https://github.com/rjhansen/nsrllookup/archive/refs/tags/1.4.2.tar.gz"
  echo "${hash}  /tmp/nsrllookup-1.4.2.tar.gz" | sha256sum -c -
  tar -xzf /tmp/nsrllookup-1.4.2.tar.gz -C /tmp/
  ( cd /tmp/nsrllookup-1.4.2 && cmake -D CMAKE_BUILD_TYPE=Release . && make && make install )
  rm -rf /tmp/nsrllookup-1.4.2 /tmp/nsrllookup-1.4.2.tar.gz
}

build_deark() {
  log "Building deark v1.6.7..."
  apt_install git build-essential
  rm -rf /usr/local/src/deark
  git clone --branch v1.6.7 --recurse-submodules --depth 1 \
    https://github.com/jsummers/deark /usr/local/src/deark
  ( cd /usr/local/src/deark && make -s && make install -s )
  rm -rf /usr/local/src/deark
}

build_dumpfloppy() {
  log "Building dumpfloppy..."
  apt_install git build-essential
  if command -v dumpfloppy >/dev/null 2>&1; then
    log "dumpfloppy already present - skipping."
    return 0
  fi
  rm -rf /tmp/dumpfloppy
  git -c http.sslVerify=false clone https://offog.org/git/dumpfloppy.git /tmp/dumpfloppy
  ( cd /tmp/dumpfloppy && aclocal --force && autoconf -f && automake --add-missing \
      && ./configure && make -s && make install -s && ldconfig )
  rm -rf /tmp/dumpfloppy
}

build_regripper() {
  log "Installing RegRipper 3.0..."
  apt_install git libparse-win32registry-perl
  rm -rf /usr/local/src/regripper
  git clone --depth 1 https://github.com/keydet89/RegRipper3.0.git /usr/local/src/regripper
  mkdir -p /usr/share/regripper
  install -m 0755 /usr/local/src/regripper/rip.pl /usr/share/regripper/rip.pl
  # RegRipper ships Windows-authored paths/shebang - point it at this box.
  sed -i \
    -e '1s|^#! c:\\perl\\bin\\perl\.exe|#!/usr/bin/perl|' \
    -e 's|my \$plugindir;|my $plugindir = "/usr/share/regripper/plugins/";|' \
    -e 's|(\$\^O eq "MSWin32") ? (\$plugindir = \$str\."plugins/")|#(\$^O eq "MSWin32") ? (\$plugindir = \$str."plugins/")|' \
    -e 's|: (\$plugindir = File::Spec->catfile(\$str, "plugins"));|#: (\$plugindir = File::Spec->catfile(\$str, "plugins"));|' \
    /usr/share/regripper/rip.pl
  ln -sfn /usr/local/src/regripper/plugins /usr/share/regripper/plugins
  ln -sf /usr/share/regripper/rip.pl /usr/local/bin/rip.pl
  install -m 0755 /usr/local/src/regripper/Base.pm /usr/share/perl5/Parse/Win32Registry/Base.pm
  install -m 0755 /usr/local/src/regripper/File.pm /usr/share/perl5/Parse/Win32Registry/WinNT/File.pm
  install -m 0755 /usr/local/src/regripper/Key.pm /usr/share/perl5/Parse/Win32Registry/WinNT/Key.pm
  # Precompute RegRipper's plugin-category index files (identical to the
  # one-liners upstream's salt states ran via cmd.wait).
  for cat in All NTUSER USRCLASS SAM Security Software System; do
    grep -R 'my %config = (hive' /usr/share/regripper/plugins 2>/dev/null \
      | grep "${cat}" \
      | cut -f1 -d: \
      | xargs -r -n1 -I{} basename {} \
      | sed 's/\.pl$//' \
      > "/usr/share/regripper/plugins/$(echo "$cat" | tr '[:upper:]' '[:lower:]')" || true
  done
}

install_adoptium_jdk() {
  if command -v java >/dev/null 2>&1 && java -version 2>&1 | grep -q '"21'; then
    return 0
  fi
  log "Installing Eclipse Temurin 21 JDK (Adoptium)..."
  apt_install software-properties-common
  mkdir -p /usr/share/keyrings
  curl -fsSL "https://packages.adoptium.net/artifactory/api/gpg/key/public" \
    -o /usr/share/keyrings/adoptium.pgp
  local codename
  codename="$(lsb_release -cs 2>/dev/null || echo noble)"
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/adoptium.pgp] https://packages.adoptium.net/artifactory/deb ${codename} main" \
    > /etc/apt/sources.list.d/adoptium.list
  apt_refresh_after_repo_change
  apt_install temurin-21-jdk
}

build_hfsexplorer() {
  local version=2021.10.9
  local hash=1dfc2183ebcd5f4ca283def3d3a0061542bdbf43d62a1c35208a4b95bf2b9d8e
  log "Installing HFSExplorer ${version}..."
  install_adoptium_jdk
  apt_install unzip
  curl -fsSL -o "/tmp/hfsexplorer-${version}-bin.zip" \
    "https://github.com/unsound/hfsexplorer/releases/download/hfsexplorer-${version}/hfsexplorer-${version}-bin.zip"
  echo "${hash}  /tmp/hfsexplorer-${version}-bin.zip" | sha256sum -c -
  rm -rf /usr/share/hfsexplorer
  mkdir -p /usr/share/hfsexplorer
  unzip -q "/tmp/hfsexplorer-${version}-bin.zip" -d /usr/share/hfsexplorer
  cat > /usr/local/bin/hfsexplorer <<'EOF'
#!/bin/bash
/usr/share/hfsexplorer/bin/hfsexplorer "$@" &
EOF
  chmod 0755 /usr/local/bin/hfsexplorer
  rm -f "/tmp/hfsexplorer-${version}-bin.zip"
}

build_jhove() {
  local hash=8652ddd84a65ab449e872f2baef7acb4c2a2212268c657788d0257b85b645498
  log "Installing JHOVE 1.34.0..."
  install_adoptium_jdk
  curl -fsSL -o /tmp/jhove.jar "https://software.openpreservation.org/rel/jhove-latest.jar"
  echo "${hash}  /tmp/jhove.jar" | sha256sum -c -
  java -jar /tmp/jhove.jar "${VENDOR_DIR}/files/auto-install.xml"
  ln -sfn /usr/local/src/jhove/jhove /usr/local/bin/jhove
  ln -sfn /usr/local/src/jhove/jhove-gui /usr/local/bin/jhove-gui
  rm -f /tmp/jhove.jar
}

install_siegfried() {
  local version=1.11.0
  local hash=95422e7cb250b4e759187e80a8a35c02ddc09e47bd95cf15c3706837de4983a3
  log "Installing siegfried ${version}..."
  curl -fsSL -o "/tmp/siegfried_${version}-1_amd64.deb" \
    "https://github.com/richardlehane/siegfried/releases/download/v${version}/siegfried_${version}-1_amd64.deb"
  echo "${hash}  /tmp/siegfried_${version}-1_amd64.deb" | sha256sum -c -
  apt_get install -y "/tmp/siegfried_${version}-1_amd64.deb" || dpkg -i "/tmp/siegfried_${version}-1_amd64.deb" || true
  rm -f "/tmp/siegfried_${version}-1_amd64.deb"
}

build_bulk_reviewer() {
  local version=0.3.1
  local hash=a1df480582468dfded74119e27573da9e7fa6ef7ecbc6dbd814cdcdfc845dadc
  log "Installing Bulk Reviewer ${version} (AppImage)..."
  apt_install libfuse-dev
  mkdir -p /usr/share/bulk-reviewer /usr/share/icons/bitcurator
  curl -fsSL -o "/usr/share/bulk-reviewer/BulkReviewer-${version}.AppImage" \
    "https://github.com/bulk-reviewer/bulk-reviewer/releases/download/v${version}/BulkReviewer-${version}.AppImage"
  echo "${hash}  /usr/share/bulk-reviewer/BulkReviewer-${version}.AppImage" | sha256sum -c -
  chmod 0755 "/usr/share/bulk-reviewer/BulkReviewer-${version}.AppImage"
  cat > /usr/local/bin/bulk-reviewer <<EOF
#!/bin/bash
/usr/share/bulk-reviewer/BulkReviewer-${version}.AppImage --no-sandbox &
EOF
  chmod 0755 /usr/local/bin/bulk-reviewer
  curl -fsSL -o /usr/share/icons/bitcurator/bulk-reviewer.png \
    "https://github.com/bulk-reviewer/bulk-reviewer/raw/main/build/icons/512x512.png" || true
}

main() {
  VENDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/vendor" && pwd)"
  apt_update_if_needed
  try build_bulk_extractor
  try build_lightgrep
  try build_nsrllookup
  try build_deark
  try build_dumpfloppy
  try build_regripper
  try build_hfsexplorer
  try build_jhove
  try install_siegfried
  try build_bulk_reviewer
  log "Build-from-source tool pass complete."
}

main "$@"
