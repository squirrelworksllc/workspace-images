# syntax=docker/dockerfile:1.7
# ----------------------------- DESCRIPTION -----------------------------
# Installs Ubuntu and gives root access to OS.
# Does NOT provide DIND (Docker-in-Docker).
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT.
# Examples:
#   Lint: docker build --target lint -f images/ubuntu-noble-desktop/Dockerfile .
#   Prod: docker build -t squirrelworksllc/ubuntu-noble-desktop:1.18.0 -f images/ubuntu-noble-desktop/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/ubuntu-noble-desktop:develop -f images/ubuntu-noble-desktop/Dockerfile .
# ----------------------------------------------------------------------

# DEV NOTE: The tag can change as Kasm changes, use stable and not rolling.
ARG BASE_TAG="1.18.0-rolling-weekly"
ARG BASE_IMAGE="core-ubuntu-noble"

# ############################################################################
# -------------------------------- BASE ----------------------------------- #
# ############################################################################
FROM kasmweb/${BASE_IMAGE}:${BASE_TAG} AS base

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR ${HOME}

# If Chrome is being installed in the image:
#   INSTALL_CHROME=true and SKIP_CHROMIUM=false (or remove skip logic entirely)
ENV INSTALL_CHROME=true

ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=${STARTUPDIR}/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=${STARTUPDIR}/install


# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

ARG HADOLINT_VERSION="v2.12.0"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install pinned hadolint (x86_64).
RUN curl -fsSL -o /usr/local/bin/hadolint \
      "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
    && chmod +x /usr/local/bin/hadolint \
    && hadolint --version

WORKDIR /src
COPY . /src

# Lint THIS Dockerfile (path inside repo)
RUN hadolint /src/images/ubuntu-noble-desktop/Dockerfile

# Shellcheck scripts
RUN find /src/src /src/tools /src/common -type f -name "*.sh" -print0 2>/dev/null | xargs -0 -r shellcheck


# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
FROM base AS build

# Install script list (kept close to the build logic)
# NOTE: This is a space-separated list; keep it quoted and split by shell.
ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/chrome/install_chrome.sh \
/ubuntu/install/firefox/install_firefox.sh \
/ubuntu/install/thunderbird/install_thunderbird.sh \
/ubuntu/install/vs_code/install_vs_code.sh \
/ubuntu/install/remmina/install_remmina.sh \
/ubuntu/install/libre_office/install_libre_office.sh \
/ubuntu/install/signal/install_signal.sh \
/ubuntu/install/gimp/install_gimp.sh \
/ubuntu/install/ansible/install_ansible.sh \
/ubuntu/install/slack/install_slack.sh \
/ubuntu/install/discord/install_discord.sh \
/ubuntu/install/teams/install_teams.sh \
/ubuntu/install/obsidian/install_obsidian.sh \
/ubuntu/install/infosec_yara/install_infosec_yara.sh \
/ubuntu/install/tesseract_ocr/install_tesseract_ocr.sh \
/ubuntu/install/common/01_cleanup.sh"

# Copy install payload from repo-root/src (contains ubuntu/)
COPY ./src/ ${INST_DIR}

# Run installations (single apt-get update here)
RUN set -eux; \
    apt-get update; \
    for SCRIPT in ${INST_SCRIPTS}; do \
      echo ">>> Running ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { echo "FAILED: ${SCRIPT}"; exit 1; }; \
    done; \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    rm -f /etc/X11/xinit/Xclients; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    rm -rf "${INST_DIR}"

# Userspace Runtime
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
