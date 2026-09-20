#!/usr/bin/env bash
###############################################################################
# install_bitcurator5.sh
#
# Installs the BitCurator 5 forensics toolset onto the SquirrelWorks Kasm
# Noble base. This is SquirrelWorks' own reimplementation of BitCurator's
# package list, tool builds, and desktop integration as plain bash - not a
# run of BitCurator's own bitcurator-cli/SaltStack installer.
#
# Why: BitCurator is not officially supported in containers, and its
# installer assumes a full, dedicated Ubuntu Desktop with systemd and a real
# login session. Repeated attempts to bridge that gap (systemd/timedatectl
# shims, a root/sudo detection workaround, a uid-shared scratch account to
# satisfy Salt's own user-management states) kept surfacing new failures
# because each fix only patched the specific incompatibility that had just
# been found. bitcurator-salt's actual package list, tool-build steps, and
# desktop assets (menu, icons, nautilus scripts, dotfiles) are mostly plain
# apt/build-from-source/static-file work under the SaltStack wrapper - see
# vendor/NOTICE.md for exactly what's vendored from upstream, under what
# license (GPLv3), and what's SquirrelWorks' own code.
#
# Orchestrates, in order:
#   1. packages.sh            - apt package batches (+ universe/multiverse)
#   2. build_tools.sh         - build-from-source / pinned-release tools
#   3. python_tools.sh        - pip tools, each in its own /opt/<tool> venv
#   4. desktop_integration.sh - BitCurator's menu, icons, mounter app,
#                               dotfiles, guymager config, documentation,
#                               and Thunar custom actions
# then Firefox-as-default-browser and a final tool sanity check.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[BITCURATOR-INSTALL] $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KASM_USER="kasm-user" # the real Kasm session account (uid 1000)

main() {
  log "======= Installing BitCurator 5 (SquirrelWorks native build) ======="

  local kasm_home
  kasm_home="$(getent passwd 1000 | cut -d: -f6 || echo /home/kasm-user)"

  bash "${SCRIPT_DIR}/packages.sh"
  bash "${SCRIPT_DIR}/build_tools.sh"
  bash "${SCRIPT_DIR}/python_tools.sh"
  bash "${SCRIPT_DIR}/desktop_integration.sh" "$kasm_home"

  # kasm-user needs the same desktop-usable groups a stock BitCurator
  # account would have, for mounting/analyzing disk images.
  for grp in sudo adm cdrom dip plugdev lpadmin lxd sambashare; do
    if getent group "$grp" >/dev/null 2>&1; then
      usermod -aG "$grp" "${KASM_USER}" || true
    fi
  done

  # --- Set Firefox as the default browser -------------------------------
  if command -v firefox >/dev/null 2>&1; then
    log "Setting Firefox as the default browser..."
    mkdir -p "${kasm_home}/.config"
    cat > "${kasm_home}/.config/mimeapps.list" <<'EOF'
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
x-scheme-handler/about=firefox.desktop
x-scheme-handler/unknown=firefox.desktop

[Added Associations]
text/html=firefox.desktop;
x-scheme-handler/http=firefox.desktop;
x-scheme-handler/https=firefox.desktop;
EOF
    chown -R 1000:0 "${kasm_home}/.config/mimeapps.list"
    update-alternatives --set x-www-browser /usr/bin/firefox >/dev/null 2>&1 || true
  else
    log "WARNING: Firefox not found - skipping default-browser configuration."
  fi

  # --- Sanity check: did the core forensic tools actually land? ----------
  local missing=0 tool
  for tool in bulk_extractor disktype fiwalk md5deep rip.pl imount \
              nsrllookup deark sf; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log "MISSING: ${tool}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    log "Core BitCurator tools present."
  else
    log "WARNING: one or more BitCurator tools are missing - review the build log above."
  fi

  log "BitCurator install stage complete."
}

main "$@"
