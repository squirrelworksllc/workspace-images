<p align="center">
  <img src="common/resources/images/Logo.png" alt="Project Logo" width="300">
</p>

# 🐳 SquirrelWorksLLC Workspace Images

This repository contains **all Docker workspace images built and maintained by SquirrelWorksLLC**.

Each image follows a **strict, repeatable, and scalable structure** designed to grow cleanly as new images are added — without constantly modifying CI workflows, VS Code tasks, or build scripts.

---

## 📑 Table of Contents

1. [Repository Overview](#repository-overview)
2. [Repository Structure](#repository-structure)
3. [Core Rules](#core-rules)
4. [Build Context](#build-context)
5. [Dockerfile Structure](#dockerfile-structure)
6. [Image Targets](#image-targets)
7. [CI & Branch Protection](#ci--branch-protection)
8. [Contribution & Required Workflow](#contribution--required-workflow)
9. [Adding a New Image](#adding-a-new-image)
10. [Manual Builds](#manual-builds)
11. [Philosophy](#philosophy)

---

## Repository Overview

Current images include:

- **ubuntu-noble-dind**
- **ubuntu-noble-desktop**
- **remnux**
- **bitcurator5**

All images are built using:
- A shared repo-root build context
- Centralized linting policy
- Dynamically generated CI matrix

---

## Repository Structure

```text
.
├── images/
│   ├── ubuntu-noble-dind/
│   ├── ubuntu-noble-desktop/
│   ├── remnux/
│   └── bitcurator5/
├── src/
│   └── ubuntu/
├── tools/
│   └── ci/
├── common/
│   └── resources/
│       └── images/
├── .vscode/
│   └── images.json
└── README.md
```

---

## Core Rules

- **Repo root is always the Docker build context**
- Each image owns its own Dockerfile under `images/<image-name>/`
- Images are registered **once** in `.vscode/images.json`
- CI automatically discovers all images
- **Lint is the enforcement gate**

---

## Build Context

All Dockerfiles assume:

```bash
docker build -f images/<image>/Dockerfile .
```

Never change the build context per-image.

---

## Dockerfile Structure

Every Dockerfile must provide:

- `base` stage
- `lint` stage
- `build` stage
- `develop` target
- `production` target (default)

Linting is centralized via:

- `tools/ci/lint_installers.sh`
- `tools/ci/lint-dockerfile.sh`
- `tools/ci/lint-shell.sh`

---

## Image Targets

| Target | Purpose |
|------|--------|
| `lint` | Static validation only |
| `build` | Shared install logic |
| `develop` | Debug-friendly image |
| `production` | Final runtime image |

---

## CI & Branch Protection

CI dynamically generates a matrix from `.vscode/images.json`.

### Enforcement Behavior

- **Lint gate is required**
- Production builds are informational only
- A PR **cannot merge** if lint fails
- Production build failures do **not** block merges

This allows active upstream projects (REMnux, BitCurator) to be worked on without blocking all changes.

---

## Contribution & Required Workflow

> **Direct pushes to `main` are intentionally blocked.**  
> This repository enforces pull-request-only changes with mandatory CI checks.

### 🚫 What Is Not Allowed

- Pushing directly to `main`
- Bypassing required CI checks
- Merging code that fails the lint gate

Attempts to push directly to `main` will be rejected by GitHub.

---

### ✅ Required Workflow

#### 1. Create a working branch

```bash
git checkout -b develop
```

Use a descriptive name for feature work when appropriate (e.g. `lint-fix`, `dockerfile-update`).

---

#### 2. Commit changes locally

```bash
git add .
git commit -m "Describe your changes"
```

---

#### 3. Push the branch

```bash
git push -u origin develop
```

---

#### 4. Open a Pull Request

Create a Pull Request targeting:

- **Base:** `main`
- **Compare:** your working branch

---

#### 5. Required status checks

The following check **must pass** before merging:

- `lint / gate`

If lint fails, update your branch and push again until the check passes.

---

#### 6. Merge

Once all required checks pass and repository rules are satisfied, the Pull Request may be merged into `main`.

---

### ℹ️ Notes

- These rules are enforced server-side by GitHub
- VS Code and Git cannot override them
- This protects the stability and consistency of `main`

If you encounter push rejections, confirm you are not pushing directly to `main`.

---

## Adding a New Image

1. Create a folder:
   ```bash
   images/<new-image>/
   ```

2. Copy the Dockerfile template

3. Register the image in `.vscode/images.json`

4. Commit and open a PR

CI will automatically:
- Add lint checks
- Enforce policy
- Include the image in gating

No CI changes required.

---

## Manual Builds

Lint:
```bash
docker build --target lint -f images/<image>/Dockerfile .
```

Production:
```bash
docker build -t squirrelworksllc/<image>:<tag> -f images/<image>/Dockerfile .
```

---

## Philosophy

> Calm infrastructure is good infrastructure.

This repository favors:
- Predictability over cleverness
- Linting over tribal knowledge
- Gates over trust

Everything here is designed so **future-you** does not have to rediscover rules the hard way.

