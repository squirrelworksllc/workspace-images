# 🐧 Ubuntu Noble Desktop Workspace Image (`ubuntu-noble-desktop`)

This directory contains the workspace configuration and documentation for the **Ubuntu Noble Desktop** image — an immutable Kasm Workspaces XFCE desktop built on top of our internal base image `squirrelworksllc/ubuntu-noble-core`.

The image is assembled by the **modular install registry**: the Dockerfile executes an ordered list of `src/ubuntu/install/<app>/install_*.sh` modules, each of which installs its package, applies UI/menu configuration via `configure_ui.sh`, and (where needed) registers a runtime `startup.sh` hook that Kasm runs at session start.

## 🛠️ Complete Technical Tool Manifest

Below is the comprehensive listing of all software pre-baked into this workspace image. Click any tool name to visit its official project documentation.

### 🌐 Web Browsers
* **[Google Chrome](https://www.google.com/chrome/)** – Enterprise-stable release (`.deb`), configured for containerized deployment with managed policies and a `--no-sandbox` wrapper.
* **[Mozilla Firefox](https://www.mozilla.org/en-US/firefox/)** – Default browser, installed from Mozilla's APT repository and version-pinned for stability.
* **[Chromium](https://www.chromium.org/Home)** – Native (non-snap) Chromium from a pinned Debian repo. **Conditional:** the Chromium module stands down when Chrome is present (`INSTALL_CHROME=true`, the default here), so a stock desktop build ships Chrome + Firefox. Set `INSTALL_CHROME=false` to get Chromium instead.

### 💼 Developer & Productivity Suite
* **[Visual Studio Code](https://code.visualstudio.com/)** – Installed from the official `.deb` channel; a runtime `startup.sh` hook keeps the user profile permissions correct across sessions.
* **[Ansible](https://www.ansible.com/)** – IT automation and configuration management engine.
* **[LibreOffice](https://www.libreoffice.org/)** – Complete open-source office productivity package.
* **[Remmina](https://remmina.org/)** – Remote desktop client supporting RDP, SSH, and VNC.
* **[GIMP](https://www.gimp.org/)** – GNU Image Manipulation Program (installed as an extracted AppImage with a sandbox-friendly launcher).
* **[Obsidian](https://obsidian.md/)** – Markdown-based knowledge base (version resolved from the upstream `desktop-releases.json` manifest).
* **[FileZilla](https://filezilla-project.org/)** – Graphical FTP, FTPS, and SFTP client.

### 💬 Communication Tools
* **[Signal](https://signal.org/)** – Secure, end-to-end encrypted messaging desktop application.
* **[Slack](https://slack.com/)** – Enterprise collaboration and team communication platform.
* **[Discord](https://discord.com/)** – Voice, video, and text communication service.
* **[Microsoft Teams](https://www.microsoft.com/en-us/microsoft-teams/group-chat-software)** – Unified communication and collaboration software (`teams-for-linux`).
* **[Telegram Desktop](https://desktop.telegram.org/)** – Cloud-based messaging client (tarball install on amd64).
* **[Mozilla Thunderbird](https://www.thunderbird.net/)** – Full-featured standalone email, newsgroup, and chat client (APT, snap-blocked and pinned).

### 🛡️ InfoSec & Document Analysis Tools
* **[Tor Browser](https://www.torproject.org/)** – Installed from the signed upstream tarball with GPG fingerprint verification.
* **[TorSocks](https://github.com/dgoulet/torsocks)** – Shell-level SOCKS proxy wrapper, plus a `torsocks-guard` helper and a "Tor SOCKS Status" launcher.
* **[qBittorrent](https://www.qbittorrent.org/)** – Lightweight P2P BitTorrent client, pre-seeded with a no-download-on-add profile.
* **[Recoll](https://www.lesbonscomptes.com/recoll/)** – Full-text desktop search for deep indexing of local documents and forensic content. Listed under **Applications → Graphics**.
* **[Tesseract OCR](https://github.com/tesseract-ocr/tesseract)** – OCR engine, with:
    * **[gImageReader](https://github.com/manisandro/gImageReader)** – graphical Tesseract frontend.
    * **[NormCap](https://github.com/dynobo/normcap)** – screen-capture OCR tool (isolated venv).
* **InfoSec YARA Suite:**
    * **[YARA](https://virustotal.github.io/yara/)** – pattern-matching engine for malware researchers.
    * **Python tooling:** `yls-yara` (YARA Language Server), `plyara`, `yara-python`.
    * **VS Code integration** via the `infosec-intern/vscode-yara` extension.
* **[Origamindee](https://github.com/mindee/origamindee)** – Ruby PDF-analysis toolkit:
    * `pdfcop` – heuristic analyzer for suspicious/malicious PDF structure.
    * `pdfdecompress` – strips stream compression filters (e.g. FlateDecode) to expose plain-text data.
* **[ZBar](https://github.com/mchehab/zbar)** – barcode / QR-code reader suite, wrapped by a `zbar-scan` launcher (webcam or file picker) and listed under **Applications → Graphics**.
* **[iocextract](https://github.com/InQuest/iocextract)** – InQuest's IOC extractor. Pulls URLs, IPv4/IPv6 addresses, domains, e-mail addresses, file hashes and YARA rules out of a document or stream and automatically re-fangs defanged indicators (`hxxp://`, `1[.]2[.]3[.]4`). Available as the `iocextract` command and a terminal launcher; full usage in the [official documentation](https://inquest.readthedocs.io/projects/iocextract/en/latest/).

> **Note:** `iocextract` replaces the former `ioc_parser` module, which was removed — the upstream project is abandoned and Python 2 only.

---

## 🖼️ Desktop Icons

Every application always appears in the XFCE **Applications menu**. Whether it *also* gets a
**Desktop** shortcut is controlled per-app by a `<APP>_DESKTOP_ICON` environment variable,
set in the Dockerfile and overridable at build time:

| Default **on** | Default **off** (opt-in) |
| --- | --- |
| `FIREFOX_DESKTOP_ICON`, `TOR_BROWSER_DESKTOP_ICON` | `CHROME`, `FILEZILLA`, `VS_CODE`, `GIMP`, `OBSIDIAN`, `QBITTORRENT`, `REMMINA`, `RECOLL`, `IOCEXTRACT`, `TORSOCKS`, `ZBAR`, `DISCORD`, `SIGNAL`, `SLACK`, `TEAMS`, `TELEGRAM`, `THUNDERBIRD` |

Set any of them to `true` / `false` via `--build-arg` (or edit the `ENV` block) to change the
default desktop layout.

---

## 📚 In-Workspace Documentation

`src/ubuntu/install/desktop/generate_desktop_docs.sh` builds an HTML catalog of everything
installed in the image, with links to each project's homepage and docs. It is available:

* from **Applications → Documentation**, and
* as a **Documentation** desktop launcher,

and is also served from the stable path `/usr/share/squirrelworks-docs/`.

---

## 🏗️ Repository Architecture Context

```text
images/ubuntu-noble-desktop/
├── Dockerfile          # Image definition (FROM squirrelworksllc/ubuntu-noble-core)
├── .dockerignore       # Build context safety filters
├── Dockerhub.info      # Short overview for the Docker Hub description
└── README.md           # This file (also baked in as the in-image Workspace Guide)
```

Build targets (shared across all images): `lint` → `build` → `develop` / `production`.
The build context is always the **repo root**. At session start Kasm runs
`/dockerstartup/custom_startup.sh`, which drives `master_startup.sh` and every per-app
`startup.sh` runtime hook.
