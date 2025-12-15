#!/usr/bin/env bash
set -euo pipefail

fail=0

check() {
  local pattern="$1"
  local msg="$2"
  if rg -n --hidden --glob '!**/.git/**' "$pattern" >/dev/null; then
    echo "FAIL: $msg"
    rg -n --hidden --glob '!**/.git/**' "$pattern" || true
    echo
    fail=1
  fi
}

check '\bapt-key\b' "apt-key is deprecated (use /etc/apt/keyrings + signed-by=)"
check '\bapt(-get)?\s+upgrade\b' "avoid apt upgrade inside images"
check 'icon-theme\.cache' "icon cache removal should only be in final cleanup"
check 'rm -rf\s+/var/lib/apt/lists' "apt lists cleanup should only be in final cleanup"

exit "$fail"