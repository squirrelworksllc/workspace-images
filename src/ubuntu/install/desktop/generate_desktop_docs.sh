#!/usr/bin/env bash
###############################################################################
# generate_desktop_docs.sh
# Purpose: Converts the repository README.md into a styled local HTML guide
#          and generates a navigable, styled HTML manifest of installed packages.
###############################################################################
set -euo pipefail

log() { echo "[DESKTOP-DOCS] $*"; }

main() {
    log "Generating local workspace documentation..."

    # Ensure the markdown parser is available
    apt-get update
    apt-get install -y --no-install-recommends python3-markdown

    # Define the Kasm skeleton desktop path
    export DESKTOP_DIR="/home/kasm-default-profile/Desktop"
    export README_PATH="/src/README.md"
    mkdir -p "${DESKTOP_DIR}"

    # 1. Generate the Raw Package Data into temporary files
    log "Dumping APT, PIP, and GEM package states..."
    
    dpkg-query -W -f='${binary:Package} (${Version})\n' > /tmp/apt_packages.txt
    
    if command -v pip3 >/dev/null 2>&1; then
        pip3 list > /tmp/pip_packages.txt
    else
        touch /tmp/pip_packages.txt
    fi

    if command -v gem >/dev/null 2>&1; then
        gem list > /tmp/gem_packages.txt
    else
        touch /tmp/gem_packages.txt
    fi

    # 2. Convert README.md and Generate the HTML Manifest via inline Python
    log "Compiling styled HTML documentation..."

    # Using 'EOF' with quotes prevents bash from evaluating Python's formatting braces
    python3 - << 'EOF'
import markdown
import sys
import os

readme_path = os.environ.get("README_PATH")
desktop_dir = os.environ.get("DESKTOP_DIR")

guide_out = os.path.join(desktop_dir, "Workspace_Guide.html")
manifest_out = os.path.join(desktop_dir, "installed_packages.html")

# ==========================================
# PART A: Generate Workspace Guide (README)
# ==========================================
if os.path.exists(readme_path):
    with open(readme_path, 'r', encoding='utf-8') as f:
        md_text = f.read()

    # Strip away the internal development architecture notes
    split_marker = "## 🏗️ Repository Architecture Context"
    if split_marker in md_text:
        md_text = md_text.split(split_marker)[0]

    # Append the link to our newly generated HTML package manifest
    md_text += "\n## 📦 Complete Package Manifest\n"
    md_text += "For a comprehensive, navigable list of every system library, python module, and ruby gem installed on this system, please see the [Installed Packages Manifest](./installed_packages.html).\n"

    # Convert to HTML
    html_body = markdown.markdown(md_text, extensions=['tables'])

    # CSS Template for Guide
    guide_template = f"""<!DOCTYPE html>
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

    with open(guide_out, 'w', encoding='utf-8') as f:
        f.write(guide_template)
else:
    print(f"Warning: {readme_path} not found. Skipping Guide generation.")

# ==========================================
# PART B: Generate Package Manifest HTML
# ==========================================
def read_temp_file(path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read().strip()
    return None

apt_data = read_temp_file('/tmp/apt_packages.txt')
pip_data = read_temp_file('/tmp/pip_packages.txt')
gem_data = read_temp_file('/tmp/gem_packages.txt')

toc_html = "<ul>"
content_html = ""

def build_section(section_id, title, data):
    global toc_html, content_html
    if data:
        # Add to Table of Contents
        toc_html += f'<li><a href="#{section_id}">{title}</a></li>'
        # Add content block with anchor, title, code block, and back-to-top link
        content_html += f'<h2 id="{section_id}">{title}</h2>'
        content_html += f'<div class="code-block"><pre>{data}</pre></div>'
        content_html += f'<a href="#toc" class="back-to-top">↑ Back to Top</a>'
        content_html += f'<hr>'

build_section("apt-pkgs", "APT Packages (System Binaries)", apt_data)
build_section("pip-pkgs", "PIP Packages (Python Modules)", pip_data)
build_section("gem-pkgs", "GEM Packages (Ruby Gems)", gem_data)

toc_html += "</ul>"

manifest_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SquirrelWorks Package Manifest</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 1000px; margin: 0 auto; padding: 2rem; background-color: #f4f6f8; }}
        .container {{ background: #fff; padding: 2rem 3rem; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }}
        h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; margin-bottom: 20px; }}
        h2 {{ color: #2980b9; margin-top: 2.5em; padding-bottom: 5px; border-bottom: 1px solid #ecf0f1; }}
        .toc-box {{ background: #fdfefe; border: 1px solid #e1e8ed; padding: 1.5rem; border-radius: 6px; margin-bottom: 2rem; }}
        .toc-box h3 {{ margin-top: 0; color: #2c3e50; }}
        a {{ color: #3498db; text-decoration: none; font-weight: 600; }}
        a:hover {{ text-decoration: underline; color: #2980b9; }}
        .back-to-top {{ display: inline-block; margin-top: 10px; font-size: 0.9em; padding: 5px 10px; background: #ecf0f1; border-radius: 4px; }}
        .back-to-top:hover {{ background: #bdc3c7; text-decoration: none; }}
        .code-block {{ background: #282c34; color: #abb2bf; padding: 1.5rem; border-radius: 6px; overflow-x: auto; max-height: 500px; overflow-y: auto; box-shadow: inset 0 2px 4px rgba(0,0,0,0.2); font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace; font-size: 0.9em; }}
        hr {{ border: 0; border-top: 1px solid #eee; margin: 3rem 0; }}
    </style>
</head>
<body>
    <div class="container">
        <h1 id="toc">SquirrelWorks OS Package Manifest</h1>
        
        <div class="toc-box">
            <h3>Table of Contents</h3>
            {toc_html}
        </div>
        
        {content_html}
    </div>
</body>
</html>"""

with open(manifest_out, 'w', encoding='utf-8') as f:
    f.write(manifest_template)
EOF

    # Clean up temporary bash files
    rm -f /tmp/apt_packages.txt /tmp/pip_packages.txt /tmp/gem_packages.txt

    # Ensure the kasm user owns/can read these root-created files on the desktop
    chmod 644 "${DESKTOP_DIR}/Workspace_Guide.html" "${DESKTOP_DIR}/installed_packages.html" 2>/dev/null || true
    chown -R 1000:0 "${DESKTOP_DIR}" 2>/dev/null || true

    log "Documentation generated successfully."
}

main "$@"
