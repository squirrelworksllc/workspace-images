WIP - NOT WORKING

# syntax=docker/dockerfile:1.7
# ----------------------------- DESCRIPTION -----------------------------
# Custom REMnux-based Kasm image.
# NOTE: This Dockerfile intentionally uses a focal desktop base (per your policy),
# and the /ubuntu/install/remnux/install_remnux.sh script handles the actual REMnux install.
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT.
# Examples:
#   Lint: docker build --target lint -f images/remnux/Dockerfile .
#   Prod: docker build -t squirrelworksllc/remnux:latest -f images/remnux/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/remnux:develop -f images/remnux/Dockerfile .
# ----------------------------------------------------------------------

# REMnux base (older Kasm focal desktop image)
ARG BASE_IMAGE="ubuntu-focal-desktop"
ARG BASE_TAG="1.16.1-rolling-weekly"

# ############################################################################
# -------------------------------- BASE ----------------------------------- #
# ############################################################################
FROM kasmweb/${BASE_IMAGE}:${BASE_TAG} AS base

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR ${HOME}

ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=${STARTUPDIR}/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=${STARTUPDIR}/install


# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
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
RUN hadolint --ignore DL3008 /src/images/ubuntu-noble-dind/Dockerfile

# Shellcheck scripts
RUN find /src/src /src/tools /src/common -type f -name "*.sh" -print0 2>/dev/null | xargs -0 -r shellcheck
USER 1000

# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
FROM base AS build

# Install script list
ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/remnux/install_remnux.sh \
/ubuntu/install/common/01_cleanup.sh"

# Copy install payload from repo-root/src (contains ubuntu/)
COPY ./src/ ${INST_DIR}

# Run installations
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
