#!/usr/bin/env bash
# runs lint checks against shell scripts
set -euo pipefail

# Lint all bash scripts in the repo that are part of the build context.
# Expected to run inside a container where the repo is copied to /src.

ROOT="${1:-/src}"

# Paths we care about
SCAN_DIRS=(
  "${ROOT}/src"
  "${ROOT}/tools"
  "${ROOT}/common"
)

# Find .sh files
mapfile -d '' files < <(
  find "${SCAN_DIRS[@]}" -type f -name "*.sh" -print0 2>/dev/null
)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "No shell scripts found under: ${SCAN_DIRS[*]}"
  exit 0
fi

echo "ShellCheck: ${#files[@]} script(s)"
# Run shellcheck once for cleaner output (no xargs exit-code weirdness)
shellcheck "${files[@]}"