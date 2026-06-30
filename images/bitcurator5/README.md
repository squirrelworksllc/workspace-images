# 🔍 BitCurator 5 Digital Forensics & Archival Workstation (`images/bitcurator5`)

This directory contains the multi-stage, target-optimized architecture for provisioning the **BitCurator 5 Archival Workstation**. By leveraging a SaltStack deployment model over our core, immutable system foundation (`squirrelworksllc/ubuntu-noble-core`), this image eliminates legacy desktop conflicts and implements advanced digital forensics tooling cleanly into modern Kasm container runtimes.

## 🛠️ Complete Technical Tool Manifest

Below is a highlighted listing of the core digital curation software and analysis frameworks pre-baked into this workspace image via the BitCurator SaltStack configuration. Click any tool name to visit its official project documentation.

### 💾 Forensic Imaging & Triage
* **[Guymager](https://guymager.sourceforge.io/)** – Free forensic imager for media acquisition.
* **[Nwipe](https://github.com/martijnvanbrummelen/nwipe)** – Secure data erasure tool.

### 🗂️ Filesystem Forensics & Reporting
* **[The Sleuth Kit (TSK)](https://www.sleuthkit.org/)** – Library and collection of command line tools for investigating disk images.
* **[Fiwalk](https://github.com/simsong/fiwalk)** – Tool for processing disk images and outputting filesystem metadata in Digital Forensics XML.
* **[BitCurator Reports](https://github.com/BitCurator/bitcurator-reports)** – Generates graphical and machine-readable reports from forensic tool outputs.

### 🧠 Data Identification & NLP
* **[Bulk Extractor](https://github.com/simsong/bulk_extractor)** – High-performance digital forensics feature extraction tool (PII, emails, etc.).
* **[Brunnhilde](https://github.com/tw4l/brunnhilde)** – Characterization tool for directories and disk images using Siegfried.
* **[BitCurator NLP](https://github.com/BitCurator/bitcurator-nlp)** – Natural language processing tools for archival collections.

### 🛡️ File & Malware Analysis
* **[ClamAV](https://www.clamav.net/)** – Open-source antivirus engine for detecting trojans, viruses, and malware.
* **[Siegfried](https://www.itforarchivists.com/siegfried/)** – Signature-based file format identification tool.
* **[Hashdeep](https://github.com/jessek/hashdeep)** – Suite of tools for computing and verifying cryptographic hashes.

### 💻 Core Workspace Utilities
* **[Visual Studio Code (VSCode)](https://code.visualstudio.com/)** – Integrated development environment mapped for the `kasm_user` context.
* **Google Chrome & Mozilla Firefox** – Enterprise-stable releases optimized for performance under XFCE/Kasm rendering.

---

## 🏗️ Architectural Lineage & Frameworks

Unlike legacy bare-metal deployments, this container implements a layered strategy over our standardized foundation layer:

```text
kasmweb/core-ubuntu-noble:1.18.0-rolling-weekly (Upstream Kasm Registry Layer)
   └── squirrelworksllc/ubuntu-noble-core (Our Immutable Base Layer)
         └── images/bitcurator5/Dockerfile (This Blueprint -> BitCurator Cloud Orchestration)
