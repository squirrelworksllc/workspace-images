#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/src}"

SCAN_DIRS=(
  "${ROOT}/src"
  "${ROOT}/tools"
  "${ROOT}/common"
)

EXCLUDES=(
  "*/custom_startup.sh"
  # Vendored, unmodified third-party BitCurator scripts (GPLv3, see
  # src/ubuntu/install/bitcurator5/vendor/NOTICE.md) - not ours to fix,
  # and several are #!/usr/bin/expect scripts shellcheck can't parse as sh.
  "*/bitcurator5/vendor/*"
)

# Build find exclusion args
EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=( -not -path "$pattern" )
done

mapfile -d '' files < <(
  find "${SCAN_DIRS[@]}" \
    -type f -name "*.sh" \
    "${EXCLUDE_ARGS[@]}" \
    -print0 2>/dev/null
)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "No shell scripts found to lint."
  exit 0
fi

echo "ShellCheck: ${#files[@]} script(s)"
shellcheck -S error "${files[@]}"
