#!/usr/bin/env bash
###############################################################################
# install_ansible.sh
# Purpose: Installs Ansible and Linting tools for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
LOG_TAG="ANSIBLE-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Ansible Automation Suite ======="

    . /etc/os-release
    apt_update_if_needed

    case "${ID}" in
        ubuntu)
            if [ "${VERSION_CODENAME:-}" != "noble" ]; then
                log "Legacy Ubuntu detected - adding Ansible PPA..."
                apt_install software-properties-common
                apt-add-repository --yes ppa:ansible/ansible
                apt_refresh_after_repo_change
            fi
            # Noble (24.04) has Ansible 9.x+ in the main repo
            apt_install ansible ansible-lint
            ;;
        debian|kali)
            apt_install ansible ansible-lint
            ;;
        *)
            log "ERROR: Unsupported distro: ${ID}" >&2
            exit 1
            ;;
    esac

    run_configure_ui
    log "Ansible installation complete."
}

main "$@"
