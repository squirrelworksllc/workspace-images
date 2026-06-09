# 🐧 Ubuntu Noble Desktop Workspace Image (`ubuntu-noble-general`)

This directory contains the workspace configuration and documentation for the **Ubuntu Noble Desktop** image, an immutable Kasm Workspaces desktop environment built on top of our internal base image `squirrelworks/ubuntu-noble-core`.

## 🛠️ Complete Technical Tool Manifest

Below is the comprehensive listing of all software, frameworks, and configuration utilities pre-baked into this workspace image, cross-referenced with `image_37b546.png`.

### 🌐 Web Browsers
* **Google Chrome** – Enterprise-stable release configured for containerized deployment.
* **Mozilla Firefox** – Standard open-source browser optimized for performance under XFCE/Kasm rendering.
* **Chromium** – Included for specialized test builds and decoupled standalone profile execution.

### 💼 Developer & Productivity Suite
* **Visual Studio Code (VSCode)** – Integrated development environment with optimized permissions for the `kasm_user` context.
* **Ansible** – IT automation and configuration management engine for platform provisioning.
* **LibreOffice** – Complete open-source office productivity package.
* **Remmina** – Remote desktop client supporting RDP, SSH, and VNC protocols.
* **GIMP** – GNU Image Manipulation Program for raster graphics editing.
* **Obsidian** – Markdown-based knowledge base and local text editing suite.
* **Filezilla** – Graphical FTP, FTPS, and SFTP client.

### 💬 Communication Tools
* **Signal** – Secure, end-to-end encrypted messaging desktop application.
* **Slack** – Enterprise collaboration and team communication platform.
* **Discord** – Voice, video, and text communication service.
* **Microsoft Teams** – Unified communication and collaboration software.
* **Telegram Desktop** – Fast and secure cloud-based messaging app client.
* **Mozilla Thunderbird** – Full-featured standalone email, newsgroup, and chat client.

### 🛡️ InfoSec & Document Analysis Tools
* **Tor Browser & TorSocks** – Anonymized web routing engine paired with shell-level SOCKS proxy wrappers.
* **QBittorrent** – Lightweight P2P BitTorrent client for secure file acquisition.
* **Recoll** – Full-text desktop search tool for deep indexing of local documents and forensic content.
* **Tesseract OCR** – Optical Character Recognition engine for automated text extraction from images.
* **Gimagereader** – Graphical frontend for the Tesseract OCR engine.
* **InfoSec Yara Suite:**
    * **Yara (v4.5.5)** – Pattern-matching Swiss Army knife for malware researchers.
    * **Python Extensions via `pip`:** `yls-yara`, `plyara`, and `yara-python`.
    * **VSCode Yara Integration** – Syntax highlighting and rule validation via the `infosec-intern/vscode-yara` extension.
* **Origamindee (Origami Framework Variant) & PDFWalker:**
    * `pdfcop` – Heuristic analyzer script to parse and detect suspicious/malicious structural anomalies within PDF objects.
    * `pdfdecompress` – Command-line utility to strip compression filters (e.g., FlateDecode) out of a PDF document to expose plain-text data streams for scanning.

---

## 🏗️ Repository Architecture Context

```text
images/ubuntu-noble-general/
├── Dockerfile          # Image definition layer (FROM squirrelworks/ubuntu-noble-core)
├── .dockerignore       # Build context safety filters
├── Dockerhub.info      # Clean overview copy-paste for Docker Hub
└── README.md           # This comprehensive documentation file
