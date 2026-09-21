# 🔍 BitCurator 5 Digital Forensics & Archival Workstation (`images/bitcurator5`)

This directory provisions the **BitCurator 5 Archival Workstation** on top of
our immutable system foundation (`squirrelworksllc/ubuntu-noble-core`).

BitCurator's own package list, tool builds, and desktop assets (menu, icons,
nautilus scripts, dotfiles) are reimplemented here as plain bash
(`src/ubuntu/install/bitcurator5/`) rather than run through BitCurator's own
`bitcurator-cli`/SaltStack installer - that installer assumes a full,
dedicated Ubuntu Desktop with systemd and a real login session, which a Kasm
container doesn't provide. See
[`src/ubuntu/install/bitcurator5/vendor/NOTICE.md`](../../src/ubuntu/install/bitcurator5/vendor/NOTICE.md)
for exactly what's vendored from upstream vs. reimplemented, and why.

* **BitCurator project:** https://bitcurator.github.io/
* **Upstream source (bitcurator-salt):** https://github.com/BitCurator/bitcurator-salt
* **License:** BitCurator's own files (menu/icons/nautilus scripts/dotfiles/
  documentation, vendored under `vendor/`) are licensed
  [**GNU GPLv3**](../../src/ubuntu/install/bitcurator5/vendor/LICENSE-GPLv3.txt)
  by the BitCurator project. SquirrelWorks' own install scripts that
  reimplement BitCurator's package/build steps are not derived from
  BitCurator's SaltStack source and are not GPL-encumbered by it.

## 🛠️ Complete Technical Tool Manifest

### 💾 Forensic Imaging & Triage
* **[Guymager](https://guymager.sourceforge.io/)** – Free forensic imager for media acquisition.
* **[Nwipe](https://github.com/martijnvanbrummelen/nwipe)** – Secure data erasure tool.
* **[imagemounter](https://github.com/ralphje/imagemounter)** – Mounts and analyzes forensic disk images.

### 🗂️ Filesystem Forensics & Reporting
* **[The Sleuth Kit (TSK)](https://www.sleuthkit.org/)** – Library and command-line tools for investigating disk images.
* **[Fiwalk](https://github.com/simsong/fiwalk)** – Processes disk images and outputs filesystem metadata as Digital Forensics XML.
* **[RegRipper 3.0](https://github.com/keydet89/RegRipper3.0)** – Windows registry data extraction and correlation.
* **[JHOVE](https://jhove.openpreservation.org/)** – File format validation and characterisation.
* **[HFSExplorer](https://github.com/unsound/hfsexplorer)** – Read HFS/HFS+ filesystem images.

### 🧠 Data Identification & Analysis
* **[Bulk Extractor](https://github.com/simsong/bulk_extractor)** – High-performance feature extraction (PII, emails, etc.) from disk images, built with both RE2 and PCRE regex scanner support.
* **[Brunnhilde](https://github.com/tw4l/brunnhilde)** – Characterizes directories/disk images using Siegfried.
* **[Siegfried](https://www.itforarchivists.com/siegfried/)** – Signature-based file format identification.
* **[analyzeMFT](https://github.com/rowingdude/analyzemft)** – Parses NTFS Master File Table records.
* **[python-evtx](https://github.com/williballenthin/python-evtx)** – Parses Windows `.evtx` event logs.
* **[opf-fido](https://github.com/openpreserve/fido)** – Format Identification for Digital Objects.
* **[bagit-python](https://github.com/LibraryOfCongress/bagit-python)** – BagIt packaging for digital transfer/archiving.
* **[deark](https://entropymine.com/deark/)** – Extracts and converts many obscure/legacy file formats.

### 🛡️ File & Malware Analysis
* **[ClamAV](https://www.clamav.net/)** – Open-source antivirus engine.
* **[Hashdeep](https://github.com/jessek/hashdeep)** – Computing and verifying cryptographic hashes (also provides `md5deep`).

### ⚠️ Deliberate Deviations from Upstream
* **No `openssh-server`.** Upstream's package list installs it for bare-metal/VM
  remote access; a Kasm session is already reached over the web UI, so baking
  a running-capable sshd plus static host keys into a shared image would just
  be unnecessary attack surface.

### 🖥️ Desktop Integration
* The BitCurator application menu (Forensics and Reporting, Imaging and
  Recovery, Packaging and Transfer, Documentation and Help, Additional
  Tools), icons, and bundled documentation are installed system-wide,
  matching a stock BitCurator desktop.
* Core mount/hash/inspect actions are also wired into Thunar's right-click
  menu (this desktop's file manager), since BitCurator's own nautilus
  scripts only surface in Nautilus.
* **Mozilla Firefox** – installed and set as the default browser.

---

## 🏗️ Architectural Lineage

```text
kasmweb/core-ubuntu-noble:1.18.0-rolling-weekly (Upstream Kasm Registry Layer)
   └── squirrelworksllc/ubuntu-noble-core (Our Immutable Base Layer)
         └── images/bitcurator5/Dockerfile (This Blueprint)
               └── src/ubuntu/install/bitcurator5/*.sh (Native package/build/desktop steps)
```
