#!/usr/bin/env bash
set -euo pipefail

# Installs lint tooling used by the Dockerfile lint stages.
# Expected to run inside the lint stage container as root.

HADOLINT_VERSION="${HADOLINT_VERSION:-v2.12.0}"

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  shellcheck

rm -rf /var/lib/apt/lists/*

# Install hadolint (amd64). If you build on arm64 later, we’ll adapt this.
curl -fsSL -o /usr/local/bin/hadolint \
  "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64"
chmod +x /usr/local/bin/hadolint

# Sanity check
hadolint --version
shellcheck --version