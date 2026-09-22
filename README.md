<p align="center">
  <img src="common/resources/images/Logo.png" alt="Project Logo" width="300">
</p>

# 🐳 SquirrelWorksLLC Workspace Images

> **Calm infrastructure is good infrastructure.**
>
> This repository is intentionally opinionated: predictable builds, strict linting, and boring releases.
> If something here feels rigid, it is by design.

---

## 📑 Table of Contents

1. [Philosophy](#-philosophy)
2. [Repository Overview](#-repository-overview)
3. [Repository Structure](#-repository-structure)
4. [Branching Model (High-Level)](#-branching-model-high-level)
5. [CI & Publishing Model](#-ci--publishing-model)
6. [Core Rules](#-core-rules)
7. [Contributing](#-contributing)

---

## 🧠 Philosophy

This repository exists to make **multi-image Docker maintenance boring and reliable**.

We explicitly optimize for:

- 🧩 **Consistency over cleverness**
- 🔒 **Gates over trust**
- 🔍 **Linting over tribal knowledge**
- 📦 **Independent images over monolithic releases**

CI is treated as a *signal*, not a punishment. Publishing is designed to be **partial and resilient** so one broken upstream project does not block all others.

If you are looking for a fast-and-loose Docker playground, this is not it.

---

## 📦 Repository Overview

This repository contains **all Docker workspace images built and maintained by SquirrelWorksLLC**.

| Image | Key | Role | Status |
| --- | --- | --- | --- |
| 🧱 **ubuntu-noble-core** | `ubuntu-noble-core` | Lean shared base layer (`FROM kasmweb/core-ubuntu-noble`). Provides the `tools`, `00_apt_helper`, `01_cleanup` and `02_remediation` modules every other image builds on. | ✅ Enabled |
| 🖥️ **ubuntu-noble-desktop** | `ubuntu-noble-desktop` | Full XFCE desktop workspace (browsers, productivity, comms, InfoSec tooling). | ✅ Enabled |
| 🔧 **ubuntu-noble-dind** | `ubuntu-noble-dind` | Docker-in-Docker workspace for dev/ops and orchestration. | ✅ Enabled |
| 🧪 **remnux** | `remnux` | REMnux malware-analysis workstation layered over core via the upstream SaltStack catalog. | ✅ Enabled |
| 🗄️ **bitcurator5** | `bitcurator5` | BitCurator 5 digital-forensics workstation (SaltStack). | 🚧 WIP — `enabled: false`, not published |

All images share:

- A **single repo-root build context**
- Centralized linting and policy enforcement (`tools/ci/`)
- A CI matrix generated from a single manifest (`images.json`) — no per-image CI edits for the GitHub pipeline
- A common multi-stage layout: `base` → `lint` → `build` → `develop` / `production`

---

## 🗂️ Repository Structure

```text
.
├── images/                     # One folder per image
│   ├── ubuntu-noble-core/       #   Dockerfile + Dockerhub.info + README
│   ├── ubuntu-noble-desktop/
│   ├── ubuntu-noble-dind/
│   ├── remnux/
│   ├── bitcurator5/
│   ├── vex_ubuntu_common.json   #   Shared OpenVEX exception profile
│   └── trivy_ubuntu_common.ignore
├── src/
│   ├── ubuntu/install/          # Modular install registry (install_*.sh + configure_ui.sh + startup.sh)
│   │   └── common/              #   Shared sourced helpers (03_scaffold, 00_apt_helper, 10_desktop_icon, …)
│   ├── ubuntu/startup/          # Runtime session startup chain (custom_startup.sh → master_startup.sh)
│   └── tools/                   # Runtime + build helpers
├── tools/
│   └── ci/                      # Lint helpers (installers / shell / Dockerfile)
├── common/
│   └── resources/images/        # Branding assets
├── .github/workflows/           # GitHub Actions: PR lint gate + develop/main publishing
├── .forgejo/workflows/          # Forgejo Actions: per-image builds, size reporting, Trivy scan
├── images.json                  # Single source of truth for the image registry
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

---

## 🌳 Branching Model (High-Level)

- **`develop`**
  - Integration and active work branch
  - Direct pushes allowed
  - CI runs for signal; partial dev publishing on push

- **`main`**
  - Protected release branch
  - Pull requests required
  - Lint gate enforced
  - Production publishing on push (after merge)

Feature and dated release-staging branches (e.g. `qN-YYYY-release`) may be used to batch a set of changes before they land on `develop`/`main`.

Detailed contributor workflow lives in **[CONTRIBUTING.md](CONTRIBUTING.md)**.

---

## 🤖 CI & Publishing Model

The image registry (`images.json`) is the single source of truth. Each entry carries its
Dockerfile path, target names (`lintTarget` / `devTarget` / `prodTarget`), tag lists, the
public repo and the internal (`repo_forge`) repo, and an `enabled` flag.

### GitHub Actions (`.github/workflows/`)

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` — **CI (Lint Gate)** | PR → `main` | Enforces that `ubuntu-noble-core` is present and enabled, then lints core plus a generated matrix of every other enabled image. **This is the merge gate.** No images are pushed. |
| `publish-develop.yml` | push → `develop` | Lints, builds the `develop` target for each image and pushes dev tags. Core is built first as a hard prerequisite. |
| `publish-production.yml` | push → `main` | Same shape against the `production` target and prod tags, with provenance + SBOM attestation. |

### Forgejo Actions (`.forgejo/workflows/`)

Per-image `build-<image>.yml` workflows build and push to the internal registry, with path
filters, a non-blocking lint step, a diff guard that skips no-op builds, and
`calculate-size.yml` (a reusable workflow that reports compressed/uncompressed image size).
`trivy-scan.yml` runs vulnerability scanning against the shared ignore/VEX profiles.

### Publishing behaviour

Publishing is intentionally **per-image and resilient**:

- Only images that build successfully are pushed; one failure does not block the others.
- Workflows may go **red for visibility** — that is signal, not enforcement.
- Images publish to both the public repo (`squirrelworksllc/<image>`) and the internal
  registry (`repo_forge`).
- Production tags are defined per-image in `images.json` and currently **do** include a
  rolling `latest`.

---

## 📏 Core Rules

- Repo root is **always** the Docker build context
- Each image owns its Dockerfile under `images/<image>/`
- Images are registered **once** in `images.json` (repo root)
- `ubuntu-noble-core` must always be present and enabled — it is a mandatory pipeline invariant
- The GitHub CI matrix auto-discovers every other enabled image
- **Lint is the enforcement gate**
- Shared install logic lives in `src/ubuntu/install/` — avoid image-specific install scripts

---

## 🤝 Contributing

If you plan to contribute, please read **[CONTRIBUTING.md](CONTRIBUTING.md)**.

That document contains:
- Required workflows
- Branch protections
- Lint expectations
- How to add or modify images

---

> **If this repository feels strict, that is intentional.**
> The goal is to make mistakes loud, recovery easy, and releases boring.
