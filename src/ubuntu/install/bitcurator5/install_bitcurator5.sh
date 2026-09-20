#!/usr/bin/env bash
###############################################################################
# install_bitcurator5.sh
#
# Installs the BitCurator 5 forensics toolset onto the SquirrelWorks Kasm Noble
# base, using the official bitcurator-cli (SaltStack) in ADDON mode.
#
# BitCurator is NOT officially supported in containers. Known friction we work
# around here:
#   * No systemd / PID 1  -> salt `service.*` states and `timedatectl` hard-fail
#     ("Failed to connect to bus: Host is down"). We divert systemctl/timedatectl
#     to no-op shims for the duration of the salt run and restore them after.
#   * policy-rc.d blocks package post-install service starts.
#   * --mode=addon keeps salt from pulling a full GNOME/MATE desktop + display
#     manager that would collide with Kasm's XFCE/KasmVNC stack.
#   * BitCurator's salt states manage --user's account/home themselves
#     (creating dotfiles, nautilus scripts, vim config, etc. under it). We
#     install as a plain, independent scratch account (`bcadmin` - their own
#     documented example name) rather than aliasing the real Kasm session
#     account (`kasm-user`, uid 1000): an earlier version of this script
#     created that alias by sharing uid 1000 (`useradd -o -u 1000 ...`), but
#     with two usernames pointing at one uid, any salt state that reverse-
#     looks-up "who owns this uid" (pwd.getpwuid) can get back the WRONG
#     name (kasm-user, since it's created earlier in the base image), which
#     lines up with the "Failed to change user to kasm_user" failures seen
#     for exactly the states doing that kind of ownership bookkeeping
#     (dotfiles, nautilus scripts, vim config) while simpler states worked
#     fine. Giving the scratch account its own unique uid removes the
#     ambiguity. We then copy the useful results into the real session home
#     (/home/kasm-user, confirmed via `whoami` in a running Kasm session)
#     ourselves afterward - see merge_into_kasm_home().
#   * The salt run is best-effort: a handful of service states WILL report
#     failure in a container; that is expected. Full log at
#     /var/log/bitcurator-install.log (and bitcurator-cli's own detailed
#     saltstack.log, copied to /var/log/bitcurator-saltstack.log).
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[BITCURATOR-INSTALL] $*"; }

BC_CLI_VERSION="${BC_CLI_VERSION:-v3.0.0}"
BC_CLI_URL="https://github.com/BitCurator/bitcurator-cli/releases/download/${BC_CLI_VERSION}/bitcurator-cli-linux"
KASM_USER="kasm-user"        # the real Kasm session account (uid 1000)
BC_USER="${BC_USER:-bcadmin}" # independent scratch account, own uid/home
BC_HOME="/home/${BC_USER}"
BC_MODE="${BC_MODE:-addon}"
BC_LOG="/var/log/bitcurator-install.log"

SYSTEMCTL_REAL="/usr/bin/systemctl"

install_shims() {
  log "Installing build-time systemd shims (no PID 1 in a container)..."
  mkdir -p /run/systemd/system

  cat > /usr/local/sbin/systemctl <<'EOF'
#!/bin/sh
# Build-time no-op shim for BitCurator salt (container has no systemd).
case "${1:-}" in
  is-active)  echo active;   exit 0 ;;
  is-enabled) echo enabled;  exit 0 ;;
  is-failed)  echo inactive; exit 1 ;;
esac
exit 0
EOF
  cat > /usr/local/sbin/timedatectl <<'EOF'
#!/bin/sh
# Bare `timedatectl` / `status` / `show` all need to print parseable
# status text - salt's timezone.get_hwclock() regexes for "RTC in local
# TZ" and hard-fails with "Failed to parse timedatectl output" (not just
# a soft skip) when the output is empty, since /run/systemd/system makes
# salt.utils.systemd.booted() true and take this codepath.
cat <<'STATUS'
               Local time: Thu 2026-01-01 00:00:00 UTC
           Universal time: Thu 2026-01-01 00:00:00 UTC
                 RTC time: Thu 2026-01-01 00:00:00
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: n/a
          RTC in local TZ: no
STATUS
exit 0
EOF
  chmod 0755 /usr/local/sbin/systemctl /usr/local/sbin/timedatectl

  # Divert the real systemctl so absolute-path callers hit the shim too.
  if [ -e "$SYSTEMCTL_REAL" ] && [ ! -e "${SYSTEMCTL_REAL}.real" ]; then
    mv "$SYSTEMCTL_REAL" "${SYSTEMCTL_REAL}.real"
    install -m 0755 /usr/local/sbin/systemctl "$SYSTEMCTL_REAL"
  fi

  # Stop apt/dpkg from trying to start services during the salt run.
  cat > /usr/sbin/policy-rc.d <<'EOF'
#!/bin/sh
exit 101
EOF
  chmod 0755 /usr/sbin/policy-rc.d

  # bitcurator-cli's own privilege check appears to look for evidence of a
  # real `sudo` invocation (e.g. SUDO_USER) rather than just EUID==0 - direct
  # root with no sudo layer (as in a Dockerfile RUN) trips "Warning: You are
  # running as root." immediately followed by "Error! You must be root to
  # execute this." in --mode=addon. It may also internally drop to --user and
  # need to sudo back up. Grant both accounts passwordless sudo for the salt
  # run only; torn down in remove_shims so it never reaches the shipped image.
  cat > /etc/sudoers.d/bitcurator-install <<EOF
${KASM_USER} ALL=(ALL) NOPASSWD: ALL
${BC_USER} ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 0440 /etc/sudoers.d/bitcurator-install
}

remove_shims() {
  log "Restoring systemd tooling..."
  rm -f /usr/local/sbin/systemctl /usr/local/sbin/timedatectl /usr/sbin/policy-rc.d
  if [ -e "${SYSTEMCTL_REAL}.real" ]; then
    rm -f "$SYSTEMCTL_REAL"
    mv "${SYSTEMCTL_REAL}.real" "$SYSTEMCTL_REAL"
  fi
  rm -rf /run/systemd/system
  rm -f /etc/sudoers.d/bitcurator-install
}

# Copies whatever BitCurator's salt states actually configured under the
# scratch account's home into the real Kasm session home, so it is present
# when a workspace actually starts (which always runs as kasm-user, never
# ${BC_USER}). Existing files in the destination win (cp -n): this only
# fills in what BitCurator added, it never clobbers the base desktop image.
merge_into_kasm_home() {
  local kasm_home="$1"
  if [ ! -d "$BC_HOME" ]; then
    log "WARNING: ${BC_HOME} doesn't exist - nothing to merge (salt-created"
    log "         config may have failed entirely; check ${BC_LOG})."
    return
  fi
  log "Merging BitCurator's user-env config from ${BC_HOME} into ${kasm_home}..."
  cp -a -n "${BC_HOME}/." "${kasm_home}/" 2>/dev/null || true
  chown -R 1000:0 "${kasm_home}"
}

main() {
  log "======= Installing BitCurator ${BC_CLI_VERSION} (mode=${BC_MODE}, user=${BC_USER}) ======="

  # --- Prerequisites -------------------------------------------------------
  apt_update_if_needed
  apt_install sudo wget curl gnupg ca-certificates git \
              python3 python3-pip build-essential perl

  local kasm_home
  kasm_home="$(getent passwd 1000 | cut -d: -f6 || echo /home/kasm-user)"

  # --- Scratch account (idempotent) ---------------------------------------
  # A plain, independent account with its own uid/home - not an alias of
  # kasm-user's uid 1000 (see header comment for why that broke salt's own
  # ownership bookkeeping). BitCurator's own docs (bitcurator/bitcurator-salt
  # README) walk through creating a user named "bcadmin" during Ubuntu's
  # install and note `sudo` "will be needed for sudo commands" - bcadmin is
  # their example ACCOUNT NAME; sudo is the one group membership they
  # actually document as required.
  if ! getent passwd "${BC_USER}" >/dev/null 2>&1; then
    log "Creating scratch account '${BC_USER}'..."
    useradd -m -s /bin/bash "${BC_USER}"
  fi
  usermod -aG sudo "${BC_USER}"

  # kasm-user (the real session account) needs the same desktop-usable
  # groups a normal BitCurator install would grant its user, so mounting/
  # analyzing disk images works once the config is merged into its home.
  for grp in sudo adm cdrom dip plugdev lpadmin lxd sambashare; do
    if getent group "$grp" >/dev/null 2>&1; then
      usermod -aG "$grp" "${KASM_USER}" || true
    fi
  done

  # --- Fetch the official CLI (release binary, renamed to `bitcurator`) ---
  log "Downloading bitcurator-cli ${BC_CLI_VERSION}..."
  wget -q --tries=3 -O /usr/local/bin/bitcurator "${BC_CLI_URL}"
  chmod 0755 /usr/local/bin/bitcurator

  # --- Run the SaltStack install (best-effort in a container) ------------
  install_shims
  trap remove_shims EXIT

  export HOME=/root
  local rc=0
  log "Applying BitCurator SaltStack states - go get coffee, this is slow..."
  # Wrapped in `sudo` (not called directly) even though we are already root -
  # see the sudoers note in install_shims() above.
  sudo -E bitcurator install --mode="${BC_MODE}" --user="${BC_USER}" </dev/null 2>&1 \
    | tee "${BC_LOG}" || rc="${PIPESTATUS[0]}"

  if [ "$rc" -ne 0 ]; then
    log "WARNING: 'bitcurator install' exited ${rc}. Service/systemd states"
    log "         fail inside a container - review ${BC_LOG}. Continuing."
  fi

  # bitcurator-cli's own summary only prints the first 10 failures and
  # points at this file for the rest ("Pay particular attention to lines
  # that start with [ERROR]") - copy it out before cleanup wipes
  # /var/cache/salt.
  cp -f /var/cache/bitcurator/cli/*/saltstack.log /var/log/bitcurator-saltstack.log 2>/dev/null || true

  merge_into_kasm_home "$kasm_home"

  # --- Desktop-collision repair (safety net; addon mode should avoid it) --
  # Shims still in place so the purge/reinstall does not trip over systemd.
  log "Ensuring the Kasm XFCE stack survived the salt run..."
  apt-get purge -y --auto-remove \
    ubuntu-desktop ubuntu-session gnome-shell gdm3 lightdm >/dev/null 2>&1 || true
  update-alternatives --set x-session-manager /usr/bin/xfce4-session >/dev/null 2>&1 || true
  apt_install pulseaudio xfce4-session

  remove_shims
  trap - EXIT

  # --- Sanity check: did the core forensic tools actually land? ----------
  local missing=0 tool
  for tool in bulk_extractor disktype fiwalk md5deep; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log "MISSING: ${tool}"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    log "Core BitCurator tools present."
  else
    log "WARNING: some BitCurator tools are missing - inspect ${BC_LOG}"
  fi

  # --- Cleanup salt artefacts, the scratch account, and a stray panel plugin
  userdel -r "${BC_USER}" >/dev/null 2>&1 || true
  rm -rf /var/cache/salt /srv/salt /srv/pillar 2>/dev/null || true
  rm -f /usr/share/xfce4/panel/plugins/power-manager-plugin.desktop 2>/dev/null || true

  log "BitCurator install stage complete (rc=${rc})."
}

main "$@"
