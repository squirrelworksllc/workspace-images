#!/usr/bin/env bash
###############################################################################
# generate_desktop_docs.sh
# Purpose: Converts the repository README.md into a styled local HTML guide
#          and generates a comprehensive text manifest of all installed packages.
###############################################################################
set -euo pipefail

log() { echo "[DESKTOP-DOCS] $*"; }

main() {
    log "Generating local workspace documentation..."

    # Ensure the markdown parser is available
    apt-get update
    apt-get install -y --no-install-recommends python3-markdown

    # Define the Kasm skeleton desktop path (copied to kasm-user on launch)
    DESKTOP_DIR="/home/kasm-default-profile/Desktop"
    mkdir -p "${DESKTOP_DIR}"

    # 1. Generate the Raw Package Manifest
    log "Dumping APT, PIP, and GEM package states..."
    MANIFEST="${DESKTOP_DIR}/installed_packages.txt"
    
    echo "========================================" > "${MANIFEST}"
    echo " SQUIRRELWORKS OS PACKAGE MANIFEST" >> "${MANIFEST}"
    echo "========================================" >> "${MANIFEST}"
    
    echo -e "\n\n>>> APT PACKAGES <<<" >> "${MANIFEST}"
    dpkg-query -W -f='${binary:Package} (${Version})\n' >> "${MANIFEST}"
    
    if command -v pip3 >/dev/null 2>&1; then
        echo -e "\n\n>>> PIP (PYTHON) PACKAGES <<<" >> "${MANIFEST}"
        pip3 list >> "${MANIFEST}" || true
    fi

    if command -v gem >/dev/null 2>&1; then
        echo -e "\n\n>>> GEM (RUBY) PACKAGES <<<" >> "${MANIFEST}"
        gem list >> "${MANIFEST}" || true
    fi

    # 2. Convert README.md to HTML via inline Python
    log "Compiling README.md into styled HTML UI..."
    
    # We assume the Dockerfile COPY command has placed README.md in /src/ or similar.
    # Adjust /src/README.md to wherever your Dockerfile temporarily holds the repo context.
    README_PATH="/src/README.md" 
    HTML_OUT="${DESKTOP_DIR}/Workspace_Guide.html"

    python3 - <<EOF
import markdown
import sys
import os

readme_path = "${README_PATH}"
html_out = "${HTML_OUT}"

if not os.path.exists(readme_path):
    print(f"Warning: {readme_path} not found. Skipping HTML generation.")
    sys.exit(0)

with open(readme_path, 'r', encoding='utf-8') as f:
    md_text = f.read()

# Strip away the internal development architecture notes
split_marker = "## 🏗️ Repository Architecture Context"
if split_marker in md_text:
    md_text = md_text.split(split_marker)[0]

# Append the link to our newly generated package manifest
md_text += "\n## 📦 Complete Package Manifest\n"
md_text += "For a raw, comprehensive list of every system library, python module, and ruby gem installed on this system, please see the [Installed Packages Manifest](./installed_packages.txt).\n"

# Convert to HTML
html_body = markdown.markdown(md_text, extensions=['tables'])

# Wrap in a clean, modern CSS template
html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Workspace Application Guide</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 900px; margin: 0 auto; padding: 2rem; background-color: #f8f9fa; }}
        .container {{ background: #fff; padding: 2rem 3rem; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; border-bottom: 2px solid #eee; padding-bottom: 10px; }}
        h2 {{ color: #34495e; margin-top: 2em; }}
        h3 {{ color: #7f8c8d; }}
        a {{ color: #3498db; text-decoration: none; font-weight: bold; }}
        a:hover {{ text-decoration: underline; }}
        ul {{ padding-left: 20px; }}
        li {{ margin-bottom: 8px; }}
        hr {{ border: 0; border-top: 1px solid #eee; margin: 2rem 0; }}
    </style>
</head>
<body>
    <div class="container">
        {html_body}
    </div>
</body>
</html>"""

with open(html_out, 'w', encoding='utf-8') as f:
    f.write(html_template)
EOF

    # Ensure kasm-user can read these files once they populate on the desktop
    chmod 644 "${DESKTOP_DIR}/Workspace_Guide.html" "${DESKTOP_DIR}/installed_packages.txt" || true

    log "Documentation generated successfully."
}

main "$@"
