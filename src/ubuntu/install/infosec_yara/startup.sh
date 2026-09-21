#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
# APP: YARA / VS Code Extensions
###############################################################################
set -e
KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

# Ensure the analyst can actually write to their VS Code extensions folder
# and the YARA language server settings. Best-effort and per-path: either dir
# may be absent, and custom_startup.sh may run unprivileged.
for D in "${KASM_HOME}/.vscode" "${KASM_HOME}/.config/Code"; do
    [ -d "$D" ] && chown -R 1000:0 "$D" 2>/dev/null || true
done
