# 🐧 REMnux Malware Analysis & Forensics Workstation (`images/remnux`)

This directory contains the multi-stage, target-optimized architecture for provisioning the **REMnux Forensic Workstation**. By leveraging a SaltStack deployment model over our core, immutable system foundation (`squirrelworksllc/ubuntu-noble-core`), this image eliminates legacy OS dependencies and implements advanced malware analysis tooling cleanly into modern Kasm container runtimes.

## 🛠️ Complete Technical Tool Manifest

Below is a highlighted listing of the core forensic software and analysis frameworks pre-baked into this workspace image via the REMnux SaltStack configuration. Click any tool name to visit its official project documentation.

### 🔍 Reverse Engineering & Disassembly
* **[Ghidra](https://ghidra-sre.org/)** – Software reverse engineering (SRE) suite developed by the NSA.
* **[Radare2](https://rada.re/n/)** – Portable reverse engineering framework and command-line hex editor.
* **[Cutter](https://cutter.re/)** – Advanced graphical user interface for the Rizin reverse engineering framework.
* **System Tracers** – Pre-configured `ltrace` and `strace` for dynamic binary execution monitoring.

### 🌐 Behavioral Analysis & Networking
* **[Wireshark](https://www.wireshark.org/)** – The world's most widely-used network protocol analyzer.
* **[INetSim](https://www.inetsim.org/)** – Software suite for simulating common internet services in a lab environment.
* **[Fakenet-ng](https://github.com/mandiant/flare-fakenet-ng)** – Next-generation dynamic network analysis tool for malware.

### 💻 Code & Script Analysis
* **[Visual Studio Code (VSCode)](https://code.visualstudio.com/)** – Integrated development environment mapped for the `kasm_user` context.
* **[YARA (v4.5.5)](https://virustotal.github.io/yara/)** – The pattern-matching Swiss Army knife for malware researchers.
* **[Volatility 3](https://github.com/volatilityfoundation/volatility3)** – Advanced memory forensics framework.
* **[Oletools](https://github.com/decalage2/oletools)** – Python tools to analyze Microsoft OLE2 files (Office documents) for malicious macros.

### 📄 Document & PE Forensics
* **[PDFiD & PDF-Parser](https://blog.didierstevens.com/programs/pdf-tools/)** – Didier Stevens' core utilities for analyzing malicious PDF structures.
* **[Pecheck](https://github.com/DidierStevens/DidierStevensSuite)** – Utility for parsing Portable Executable (PE) headers.
* **[Wine](https://www.winehq.org/)** – Compatibility layer for executing un-sandboxed Windows malware binaries (.exe) dynamically within the container shell.

### 🌍 Web Browsers
* **[Google Chrome](https://chromeenterprise.google/)** – Enterprise-stable release.
* **[Mozilla Firefox](https://www.mozilla.org/en-US/firefox/)** – Standard open-source browser optimized for performance under XFCE/Kasm rendering.

---

## 🏗️ Architectural Lineage & Frameworks

Unlike legacy images pinned to Ubuntu 20.04 (Focal), this container implements a layered strategy over our standardized foundation layer:

```text
kasmweb/core-ubuntu-noble:1.18.0-rolling-weekly (Upstream Kasm Registry Layer)
   └── squirrelworksllc/ubuntu-noble-core (Our Immutable Base Layer)
         └── images/remnux/Dockerfile (This Blueprint -> REMnux Cloud Orchestration)
