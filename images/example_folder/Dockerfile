# syntax=docker/dockerfile:1.7
# ----------------------------- DESCRIPTION -----------------------------
# Template Kasm image Dockerfile (repo-root build context).
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT (.)
# ----------------------------------------------------------------------

# ----------------------------- BASE CONFIG -----------------------------
# If you are basing on an official Kasm image:
ARG BASE_IMAGE="core-ubuntu-noble"
ARG BASE_TAG="1.18.0"

# If you are basing on one of YOUR images instead, swap the FROM line below to:
#   ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-dind"
#   ARG BASE_TAG="1.18.0"
#   FROM ${BASE_IMAGE}:${BASE_TAG} AS base
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

# ----------------------------- LINT TARGET -----------------------------
FROM base AS lint
# ... install shellcheck + hadolint ...

WORKDIR /src
COPY . /src

RUN bash /src/tools/ci/lint_installers.sh
RUN hadolint /src/images/ubuntu-noble-dind/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ----------------------------- BUILD TARGET -----------------------------
FROM base AS build

# If your image uses installer scripts under repo-root/src/ubuntu/install/<something>/,
# set them here. Keep it space-separated.
ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/common/01_cleanup.sh"

# Copy install payload from repo-root/src (contains ubuntu/)
COPY ./src/ ${INST_DIR}

# Run installs (single apt-get update here)
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

# Userspace runtime
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000

CMD ["--tail-log"]

# ----------------------------- DEVELOP IMAGE ---------------------------
FROM build AS develop
ENV DEBUG=true

# Add dev-only packages/tools here if you want (optional)
# USER root
# RUN apt-get update && apt-get install -y --no-install-recommends vim && rm -rf /var/lib/apt/lists/*
# USER 1000

# ----------------------------- PRODUCTION IMAGE ------------------------
FROM build AS production
ENV DEBUG=false
