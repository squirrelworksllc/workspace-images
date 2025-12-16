<p align="center">
  <img src="common/resources/images/Logo.png" alt="Project Logo" width="300">
</p>

# 🐳 SquirrelWorksLLC Workspace Images – Repository Guide

This directory contains **all Docker images built and maintained by this repository**.  
Each image lives in its own folder and follows the same structure, targets, and build rules.

If you follow this guide, you will:
- avoid Docker build-context problems
- get consistent linting for free
- never touch VS Code tasks again
- keep builds predictable and boring (the good kind)

---

## 📁 Directory Structure

```text
repo-root/
├─ images/
│  ├─ ubuntu-noble-dind/
│  │  ├─ Dockerfile
│  │  └─ README.md
│  ├─ ubuntu-noble-desktop/
│  │  ├─ Dockerfile
│  │  └─ README.md
│  ├─ remnux/
│  │  ├─ Dockerfile
│  │  └─ README.md
│  ├─ bitcurator/
│  │  ├─ Dockerfile
│  │  └─ README.md
│  └─ README.md   ← (this file)
│
├─ src/
├─ tools/
├─ common/
└─ .vscode/
   ├─ images.json
   ├─ docker-build.sh
   └─ tasks.json
```

---

## 🧠 Core Rules (Read Once)

1. **All Docker builds use the repo root (`.`) as the build context**
2. **Each image lives in its own folder under `images/`**
3. **Every Dockerfile supports the same targets**:
   - `lint`
   - `develop`
   - `production` (default / final stage)
4. **You never edit `tasks.json` when adding new images**
5. **Image names and tags are defined once in `.vscode/images.json`**

---

## 📦 Build Context (Critical)

All images assume the **build context is the repo root**:

```bash
docker build -f images/<image-name>/Dockerfile .
```

This is required because Dockerfiles copy files from:
- `src/`
- `tools/`
- `common/`

### ❌ Wrong (will break COPY)
```bash
docker build images/<image-name>
```

### ✅ Correct
```bash
docker build -f images/<image-name>/Dockerfile .
```

---

## 🧩 Required Dockerfile Layout

Every Dockerfile under `images/` must follow this structure:

```dockerfile
FROM <base> AS base

FROM base AS lint
# hadolint + shellcheck

FROM base AS build
# installation logic

FROM build AS develop
# dev tweaks

FROM build AS production
# prod image (final stage)
```

### Why this matters
- Lint behaves consistently
- VS Code build picker works for every image
- CI/CD remains predictable
- Base images can be swapped cleanly

---

## 🧪 Target Definitions

### `lint`
- Runs **Hadolint** on the Dockerfile
- Runs **ShellCheck** on scripts in:
  - `src/`
  - `tools/`
  - `common/`
- Fails fast before wasting build time

### `develop`
- Same as production, but with:
  - `DEBUG=true`
  - optional dev-only tooling
- Tagged as `:develop`

### `production`
- Final stage
- Built when no `--target` is specified
- Tagged with a version or `latest`

---

## ➕ Adding a New Image (Step-by-Step)

### 1️⃣ Create the image folder

```text
images/my-new-image/
├─ Dockerfile
└─ README.md
```

Use the provided **template Dockerfile** as your starting point.

---

### 2️⃣ Write the Dockerfile

Required rules:
- Build context must be repo root (`.`)
- Lint target must reference the correct path:

```dockerfile
RUN hadolint /src/images/my-new-image/Dockerfile
```

Installer scripts should live under:

```text
src/ubuntu/install/<feature>/
```

---

### 3️⃣ Register the image in `.vscode/images.json`

Add **one object** to the `images` array:

```json
{
  "key": "my-new-image",
  "dockerfile": "images/my-new-image/Dockerfile",
  "context": ".",
  "repo": "squirrelworksllc/my-new-image",
  "prodTag": "1.0.0",
  "devTag": "develop",
  "devTarget": "develop",
  "lintTarget": "lint",
  "lintContext": "."
}
```

✅ That’s it.  
🚫 Do **not** modify:
- `.vscode/tasks.json`
- `.vscode/docker-build.sh`

---

## ▶️ Building Images

### From VS Code
1. **Terminal → Run Task**
2. Choose:
   - `docker: build (prod)`
   - `docker: build (develop)`
   - `docker: lint`
3. Select the image from the picker

### From CLI (repo root)

```bash
# lint
docker build --target lint -f images/my-new-image/Dockerfile .

# develop
docker build --target develop -t squirrelworksllc/my-new-image:develop   -f images/my-new-image/Dockerfile .

# production
docker build -t squirrelworksllc/my-new-image:1.0.0   -f images/my-new-image/Dockerfile .
```

---

## ⚠️ Common Mistakes

### ❌ Using the image folder as context
```bash
docker build images/my-new-image
```
Breaks `COPY ./src`.

### ✅ Always do this
```bash
docker build -f images/my-new-image/Dockerfile .
```

---

### ❌ Editing VS Code tasks per image
This repo intentionally avoids that.

If you feel the need to edit `tasks.json`, something has gone wrong.

---

### ❌ Skipping lint
Lint exists to save time.

If lint fails:
1. Fix lint
2. Rebuild
3. Then move on

---

## 🧹 Repo-wide Requirement: `.dockerignore`

The repo root **must** contain a `.dockerignore`.

Example:

```dockerignore
.git
.vscode
**/node_modules
**/.venv
**/__pycache__
**/*.log
**/dist
**/build
```

Without this, builds will be slow and noisy.

---

## 🧠 Philosophy

- Dockerfiles should be boring
- Image metadata lives in one place
- Adding images is mechanical, not creative
- Lint fails early and loudly
- Tooling stays out of your way

If you follow this pattern, everything stays calm—and that’s the goal.
