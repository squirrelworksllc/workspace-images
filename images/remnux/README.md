# 🐧 REMnux Malware Analysis & Forensics Workstation (`images/remnux`)

This directory contains the build for the **REMnux Forensic Workstation** image. It layers the upstream [REMnux](https://remnux.org/) SaltStack catalog on top of our immutable base image `squirrelworksllc/ubuntu-noble-core`, replacing REMnux's legacy Ubuntu 20.04 assumptions with a modern Noble + Kasm runtime.

## 🏗️ Build Model

The Dockerfile runs in two phases:

1. **SquirrelWorks pre-conditioning** — via the modular install registry:
   * `gnome_keyring` stub (prevents REMnux Salt `service.*` states from failing in a container)
   * Firefox, Visual Studio Code, Wireshark, Wine
   * Branded desktop / XFCE configuration (`desktop/install.sh remnux`)
2. **REMnux core install** — `remnux install --mode=cloud --user=kasm-user`, followed by
   PulseAudio restoration, the shared SquirrelWorks cleanup pass, and profile merge into the
   Kasm default profile.

Everything under the REMnux catalog below is provided and versioned by the **upstream REMnux
Salt states** (cloud mode), not pinned by this repository.

## 🛠️ Highlighted Tool Manifest

A selection of what the REMnux catalog installs. Click any tool name for its project docs.

### 🔍 Reverse Engineering & Disassembly
* **[Ghidra](https://ghidra-sre.org/)** – NSA software reverse engineering suite.
* **[radare2](https://rada.re/n/)** / **[Rizin](https://rizin.re/)** – reverse-engineering frameworks and hex editors.
* **[Cutter](https://cutter.re/)** – graphical frontend for Rizin.
* **System tracers** – `ltrace`, `strace` for dynamic execution monitoring.

### 🌐 Behavioral Analysis & Networking
* **[Wireshark](https://www.wireshark.org/)** – network protocol analyzer (installed in the pre-conditioning phase).
* **[INetSim](https://www.inetsim.org/)** – simulates common internet services in a lab.
* **[FakeNet-NG](https://github.com/mandiant/flare-fakenet-ng)** – dynamic network analysis for malware.

### 💻 Code & Script Analysis
* **[Visual Studio Code](https://code.visualstudio.com/)** – mapped for the `kasm-user` context (pre-conditioning phase).
* **[YARA](https://virustotal.github.io/yara/)** – pattern-matching engine for malware researchers.
* **[Volatility 3](https://github.com/volatilityfoundation/volatility3)** – memory forensics framework.
* **[oletools](https://github.com/decalage2/oletools)** – analysis of OLE2 / Office documents for malicious macros.

### 📄 Document & PE Forensics
* **[PDFiD & pdf-parser](https://blog.didierstevens.com/programs/pdf-tools/)** – Didier Stevens' malicious-PDF utilities.
* **[pecheck](https://github.com/DidierStevens/DidierStevensSuite)** – Portable Executable header parsing.
* **[Wine](https://www.winehq.org/)** – compatibility layer for detonating Windows binaries inside the container (pre-conditioning phase).

### 🌍 Web Browser
* **[Mozilla Firefox](https://www.mozilla.org/en-US/firefox/)** – installed from Mozilla's APT repository (pre-conditioning phase).

---

## 🧬 Architectural Lineage

```text
kasmweb/core-ubuntu-noble:1.18.0-rolling-weekly      (upstream Kasm base)
   └── squirrelworksllc/ubuntu-noble-core            (our immutable base layer)
         └── images/remnux/Dockerfile                (pre-conditioning + REMnux cloud install)
```

```text
images/remnux/
├── Dockerfile          # Two-phase build (prereqs → REMnux SaltStack, cloud mode)
├── .dockerignore       # Build context safety filters
├── Dockerhub.info      # Short overview for the Docker Hub description
└── README.md           # This file (also baked in as the in-image Workspace Guide)
```

Build targets (shared across all images): `lint` → `build` → `develop` / `production`.
The build context is always the **repo root**. At session start Kasm runs
`/dockerstartup/custom_startup.sh`, which drives `master_startup.sh` and every per-app
`startup.sh` runtime hook.

> **amd64 only.** The REMnux installer refuses to run on other architectures.
