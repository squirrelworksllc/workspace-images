# syntax=docker/dockerfile:1.7

# ----------------------------- DESCRIPTION -----------------------------
# REMnux (Kasm-compatible) for Ubuntu Noble.
#
# Built on the SquirrelWorks Ubuntu Noble core image and extended with the
# official REMnux installer (https://remnux.org/remnux), aligned with
# REMnux upstream Dockerfile.noble (--mode=cloud). Keeps Kasm entrypoint
# and users (kasm-user, kasm-default-profile).
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT.
# Example builds:
#   Lint: docker build --target lint -f images/remnux/Dockerfile .
#   Prod: docker build -t squirrelworksllc/remnux:1.18.0 -f images/remnux/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/remnux:develop -f images/remnux/Dockerfile .
# ----------------------------------------------------------------------

ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="1.18.0"

# ############################################################################
# -------------------------------- BASE ----------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE}:${BASE_TAG} AS base
USER root

ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=/dockerstartup/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=/dockerstartup/install

WORKDIR ${HOME}

# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM base AS lint
WORKDIR /src
COPY . /src

RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/remnux/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
FROM --platform=$BUILDPLATFORM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Guard: fail fast if build context isn't repo root (COPY fails if missing)
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# Copy ubuntu install tree (for install_tools.sh, 01_cleanup.sh, helpers)
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

# Validation script
RUN mkdir -p /dockerstartup/tools
COPY ./src/tools/runtime/runtime_validation.sh /dockerstartup/tools/runtime_validation.sh
RUN chmod 0755 /dockerstartup/tools/runtime_validation.sh

# 1) Base tools (curl, gnupg, git, etc.) so REMnux installer can run
RUN apt-get update && bash "${INST_DIR}/ubuntu/install/tools/install_tools.sh"

# 2) REMnux: official installer (upstream Noble style) + purge + cleanup
#    Ref: https://github.com/REMnux/docker/blob/master/remnux-distro/Dockerfile.noble
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    if [ "${ARCH}" != "amd64" ]; then \
      echo "REMnux is amd64-only; current arch: ${ARCH}"; exit 1; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl gnupg git; \
    curl -fsSL -o /tmp/remnux-installer https://remnux.org/remnux; \
    chmod +x /tmp/remnux-installer; \
    /tmp/remnux-installer install --mode=cloud --user=kasm-user; \
    apt-get purge -y \
      snapd libbison-dev docker-ce-cli \
      code \
      winehq-staging wine-staging wine-staging-amd64 wine-staging-i386 \
      scdbg runsc \
      || true; \
    apt-get autoremove -y; \
    apt-get clean; \
    if [ -f /var/cache/cast/installer/logs/results.yaml ]; then \
      mv /var/cache/cast/installer/logs/results.yaml /root/cast-results.yaml; \
    fi; \
    find /opt -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true; \
    find /opt -name '*.pyc' -delete 2>/dev/null || true; \
    rm -rf /var/lib/apt/lists/* \
           /var/backups/* \
           /var/log/journal/* \
           /var/log/vmware* \
           /var/log/kern.log \
           /var/log/auth.log \
           /var/log/alternatives.log \
           /var/log/dpkg.log \
           /var/log/syslog \
           /var/log/apt/* \
           /var/cache/cast/* \
           /var/cache/salt/* \
           /usr/share/doc/* \
           /usr/share/ri/* \
           /usr/local/src/* \
           /usr/local/yara-rules/.git 2>/dev/null || true \
           /usr/local/shellcode2exe-bat 2>/dev/null || true \
           /usr/local/ssview 2>/dev/null || true \
           /opt/scdbg 2>/dev/null || true \
           /root/.cache/* 2>/dev/null || true \
           /root/.cpan 2>/dev/null || true \
           /tmp/* \
           /var/tmp/*; \
    mkdir -p /var/cache/cast/installer/logs; \
    if [ -f /root/cast-results.yaml ]; then \
      mv /root/cast-results.yaml /var/cache/cast/installer/logs/results.yaml; \
    fi

# 3) Kasm-oriented cleanup (xdg autostart, caches, apt lists)
RUN SKIP_CLEAN=false bash "${INST_DIR}/ubuntu/install/common/01_cleanup.sh" || true

# 4) Kasm permissions and runtime setup
RUN "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    rm -rf "${INST_DIR}"

ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000
CMD ["--tail-log"]

# ############################################################################
# ------------------------------- DEVELOP --------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM build AS develop
ENV DEBUG=true

# ############################################################################
# ----------------------------- PRODUCTION -------------------------------- #
# ############################################################################
FROM --platform=$BUILDPLATFORM build AS production
ENV DEBUG=false
