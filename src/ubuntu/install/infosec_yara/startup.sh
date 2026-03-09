#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
# APP: YARA / VS Code Extensions
###############################################################################
set -e
KASM_HOME=$(getent passwd 1000 | cut -d: -f6)

# Ensure the analyst can actually write to their VS Code extensions folder
# and the YARA language server settings.
if [ -d "${KASM_HOME}/.vscode" ]; then
    chown -R 1000:1000 "${KASM_HOME}/.vscode"
    chown -R 1000:1000 "${KASM_HOME}/.config/Code"
fi
