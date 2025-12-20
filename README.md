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

1. [Philosophy](#philosophy)
2. [Repository Overview](#repository-overview)
3. [Repository Structure](#repository-structure)
4. [Branching Model (High-Level)](#branching-model-high-level)
5. [CI & Publishing Model](#ci--publishing-model)
6. [Core Rules](#core-rules)
7. [Contributing](#contributing)

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

Current images include:

- 🖥️ **ubuntu-noble-desktop**
- 🔧 **ubuntu-noble-dind**
- 🧪 **remnux**
- 🗄️ **bitcurator5**

All images share:

- A **single repo-root build context**
- Centralized linting and policy enforcement
- A dynamically generated CI matrix (no per-image CI edits)

---

## 🗂️ Repository Structure

```text
.
├── images/                 # One folder per image
│   ├── ubuntu-noble-dind/
│   ├── ubuntu-noble-desktop/
│   ├── remnux/
│   └── bitcurator5/
├── src/
│   └── ubuntu/             # Shared install logic
├── tools/
│   └── ci/                 # Lint + CI helpers
├── common/
│   └── resources/
│       └── images/         # Branding assets
├── .vscode/
│   └── images.json         # Single source of truth for images
├── CONTRIBUTING.md
└── README.md
```

---

## 🌳 Branching Model (High-Level)

- **`develop`**
  - Integration and active work branch
  - CI runs for signal
  - Partial dev publishing

- **`main`**
  - Protected release branch
  - Pull requests required
  - Lint gate enforced
  - Production publishing

Detailed contributor workflow lives in **[CONTRIBUTING.md](CONTRIBUTING.md)**.

---

## 🤖 CI & Publishing Model

### CI (Build / Test)

- Matrix generated dynamically from `.vscode/images.json`
- **Lint always runs first** and is the enforcement gate
- Dev and prod builds are informational

### Publishing

Publishing is intentionally **per-image and resilient**:

- 🧪 **Develop publishes** on push to `develop`
  - Only images that successfully build are pushed
  - Failures do not block other images
  - Workflow may go red for visibility

- 🚀 **Production publishes** on push to `main`
  - Same partial-publish behavior
  - No `:latest` tags
  - Tags defined per-image

Red workflows provide **signal**, not enforcement.

---

## 📏 Core Rules

- Repo root is **always** the Docker build context
- Each image owns its Dockerfile under `images/<image>/`
- Images are registered **once** in `.vscode/images.json`
- CI auto-discovers all images
- **Lint is the enforcement gate**

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