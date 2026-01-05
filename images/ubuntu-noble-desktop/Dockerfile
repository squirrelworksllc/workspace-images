# syntax=docker/dockerfile:1.7

# ----------------------------- DESCRIPTION -----------------------------
# Ubuntu Noble Desktop (Kasm-compatible).
#
# Built on the SquirrelWorks Ubuntu Noble core image and extended with a
# full desktop environment and common desktop applications.
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT.
# Example builds:
#   Lint: docker build --target lint -f images/ubuntu-noble-desktop/Dockerfile .
#   Prod: docker build -t squirrelworksllc/ubuntu-noble-desktop:1.18.0 -f images/ubuntu-noble-desktop/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/ubuntu-noble-desktop:develop -f images/ubuntu-noble-desktop/Dockerfile .
# ----------------------------------------------------------------------

# ----------------------------- BASE IMAGE -----------------------------
ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="1.18.0"

# ############################################################################
# ------------------------------ BASE STAGE -------------------------------- #
# ############################################################################
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

USER root

ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=/dockerstartup/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=/dockerstartup/install \
    INSTALL_CHROME=true

WORKDIR ${HOME}

# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

WORKDIR /src
COPY . /src

# installs hadolint + shellcheck
RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/ubuntu-noble-desktop/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# -------------------------- COMMON BUILD TARGET --------------------------- #
# ############################################################################
FROM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Guard: fail fast if build context isn't repo root (COPY fails if missing)
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# Copy ubuntu/ into /dockerstartup/install/ubuntu/
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

# Make installer scripts executable (avoid surprises)
RUN set -eux; \
    find "${INST_DIR}/ubuntu/install" -maxdepth 4 -type f -name '*.sh' -exec chmod +x {} \;

# Move validation script to base tools folder.
RUN mkdir -p /dockerstartup/tools
COPY ./src/tools/runtime/runtime_validation.sh /dockerstartup/tools/runtime_validation.sh
RUN chmod 0755 /dockerstartup/tools/runtime_validation.sh

# Run Installs
#
# Debug toggle:
#   docker build --progress=plain --no-cache --build-arg APT_DEBUG=true ...
ARG APT_DEBUG=false

RUN set -eux; \
    apt-get update; \
    \
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/chrome/install_chrome.sh" \
      "/ubuntu/install/firefox/install_firefox.sh" \
      "/ubuntu/install/thunderbird/install_thunderbird.sh" \
      "/ubuntu/install/vs_code/install_vs_code.sh" \
      "/ubuntu/install/remmina/install_remmina.sh" \
      "/ubuntu/install/libre_office/install_libre_office.sh" \
      "/ubuntu/install/signal/install_signal.sh" \
      "/ubuntu/install/gimp/install_gimp.sh" \
      "/ubuntu/install/ansible/install_ansible.sh" \
      "/ubuntu/install/slack/install_slack.sh" \
      "/ubuntu/install/discord/install_discord.sh" \
      "/ubuntu/install/teams/install_teams.sh" \
      "/ubuntu/install/obsidian/install_obsidian.sh" \
      "/ubuntu/install/infosec_yara/install_infosec_yara.sh" \
      "/ubuntu/install/tesseract_ocr/install_tesseract_ocr.sh" \
      "/ubuntu/install/tor_browser/install_tor_browser.sh" \
      "/ubuntu/install/torboost/install_torboost.sh" \
      "/ubuntu/install/recoll/install_recoll.sh" \
      "/ubuntu/install/desktop/set_wallpaper.sh" \
      "/ubuntu/install/common/01_cleanup.sh" \
    ); \
    \
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Running ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { \
        rc=$?; \
        echo "FAILED: ${SCRIPT} (rc=$rc)"; \
        if [ "${APT_DEBUG}" = "true" ]; then \
          echo "----- apt logs (tail) -----"; \
          tail -n 200 /var/log/apt/term.log 2>/dev/null || true; \
          tail -n 200 /var/log/apt/history.log 2>/dev/null || true; \
          echo "----- dpkg log (tail) -----"; \
          tail -n 200 /var/log/dpkg.log 2>/dev/null || true; \
          echo "----- free -h -----"; \
          free -h || true; \
          echo "----- df -h -----"; \
          df -h || true; \
          echo "----- ps (top RSS) -----"; \
          ps aux --sort=-rss | head -n 15 || true; \
        fi; \
        exit "$rc"; \
      }; \
    done; \
    \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    rm -f /etc/X11/xinit/Xclients; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    rm -rf "${INST_DIR}"

ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000
CMD ["--tail-log"]

# ############################################################################
# ------------------------------- DEVELOP IMAGE ---------------------------- #
# ############################################################################
FROM build AS develop
ENV DEBUG=true

# ############################################################################
# ----------------------------- PRODUCTION IMAGE --------------------------- #
# ############################################################################
FROM build AS production
ENV DEBUG=false
