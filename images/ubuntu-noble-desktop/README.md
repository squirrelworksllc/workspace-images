# 🐧 Ubuntu Noble Desktop Workspace Image (`ubuntu-noble-general`)

This directory contains the workspace configuration and documentation for the **Ubuntu Noble Desktop** image, an immutable Kasm Workspaces desktop environment built on top of our internal base image `squirrelworks/ubuntu-noble-core`.

## 🛠️ Complete Technical Tool Manifest

Below is the comprehensive listing of all software, frameworks, and configuration utilities pre-baked into this workspace image. Click any tool name to visit its official project documentation.

### 🌐 Web Browsers
* **[Google Chrome](https://www.google.com/chrome/)** – Enterprise-stable release configured for containerized deployment.
* **[Mozilla Firefox](https://www.mozilla.org/en-US/firefox/)** – Standard open-source browser optimized for performance under XFCE/Kasm rendering.
* **[Chromium](https://www.chromium.org/Home)** – Included for specialized test builds and decoupled standalone profile execution.

### 💼 Developer & Productivity Suite
* **[Visual Studio Code (VSCode)](https://code.visualstudio.com/)** – Integrated development environment with optimized permissions for the `kasm_user` context.
* **[Ansible](https://www.ansible.com/)** – IT automation and configuration management engine for platform provisioning.
* **[LibreOffice](https://www.libreoffice.org/)** – Complete open-source office productivity package.
* **[Remmina](https://remmina.org/)** – Remote desktop client supporting RDP, SSH, and VNC protocols.
* **[GIMP](https://www.gimp.org/)** – GNU Image Manipulation Program for raster graphics editing.
* **[Obsidian](https://obsidian.md/)** – Markdown-based knowledge base and local text editing suite.
* **[Filezilla](https://filezilla-project.org/)** – Graphical FTP, FTPS, and SFTP client.

### 💬 Communication Tools
* **[Signal](https://signal.org/)** – Secure, end-to-end encrypted messaging desktop application.
* **[Slack](https://slack.com/)** – Enterprise collaboration and team communication platform.
* **[Discord](https://discord.com/)** – Voice, video, and text communication service.
* **[Microsoft Teams](https://www.microsoft.com/en-us/microsoft-teams/group-chat-software)** – Unified communication and collaboration software.
* **[Telegram Desktop](https://desktop.telegram.org/)** – Fast and secure cloud-based messaging app client.
* **[Mozilla Thunderbird](https://www.thunderbird.net/)** – Full-featured standalone email, newsgroup, and chat client.

### 🛡️ InfoSec & Document Analysis Tools
* **[Tor Browser](https://www.torproject.org/) & TorSocks** – Anonymized web routing engine paired with shell-level SOCKS proxy wrappers.
* **[QBittorrent](https://www.qbittorrent.org/)** – Lightweight P2P BitTorrent client for secure file acquisition.
* **[Recoll](https://www.lesbonscomptes.com/recoll/)** – Full-text desktop search tool for deep indexing of local documents and forensic content.
* **[Tesseract OCR](https://github.com/tesseract-ocr/tesseract)** – Optical Character Recognition engine for automated text extraction from images.
* **[Gimagereader](https://github.com/manisandro/gImageReader)** – Graphical frontend for the Tesseract OCR engine.
* **InfoSec Yara Suite:**
    * **[Yara (v4.5.5)](https://virustotal.github.io/yara/)** – Pattern-matching Swiss Army knife for malware researchers.
    * **Python Extensions via `pip`:** `yls-yara`, `plyara`, and `yara-python`.
    * **VSCode Yara Integration** – Syntax highlighting and rule validation via the `infosec-intern/vscode-yara` extension.
* **[Origamindee](https://github.com/mindee/origamindee) (Origami Framework Variant):**
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
