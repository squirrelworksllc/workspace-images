<p align="center">
  <img src="common/resources/images/Logo.png" alt="Project Logo" width="300">
</p>

# 🤝 Contributing to SquirrelWorksLLC Workspace Images

> **This repository is intentionally strict.**
> The goal is to prevent accidental breakage across multiple images and release streams.

---

## 📑 Table of Contents

1. [Rules of Engagement](#rules-of-engagement)
2. [Branching & Workflow](#branching--workflow)
3. [CI & Lint Gate](#ci--lint-gate)
4. [Adding or Modifying Images](#adding-or-modifying-images)
5. [Local Builds & Testing](#local-builds--testing)
6. [Common Pitfalls](#common-pitfalls)

---

## 🚦 Rules of Engagement

### Non-Negotiable Rules

- ❌ **Do not push directly to `main`**
- ❌ **Do not bypass required CI checks**
- ❌ **Do not merge failing lint builds**

These rules are enforced by GitHub branch protections.

---

## 🌳 Branching & Workflow

### Branch Roles

- **`develop`**
  - Active development and integration
  - Direct pushes allowed
  - CI runs for signal

- **`main`**
  - Release branch
  - Pull requests required
  - Lint gate enforced

### Typical Workflow

```bash
git checkout develop
git pull origin develop
# make changes
git add .
git commit -m "Describe your change"
git push origin develop
```

Then:

1. Open a Pull Request
   - **Base:** `main`
   - **Compare:** `develop` (or your feature branch)
2. Fix any lint failures
3. Merge when checks pass

After merging, `develop` is synced back to `main`.

---

## 🤖 CI & Lint Gate

### What CI Does

- Generates a build matrix from `.vscode/images.json`
- Runs **lint first** (Dockerfile + shell + installers)
- Builds dev and prod targets for signal

### Enforcement

- Lint failures **block merges to `main`**
- Dev and prod build failures do **not** block other images
- Publish workflows may go red for visibility

CI output in the Actions tab is the **source of truth**, not email notifications.

---

## ➕ Adding or Modifying Images

### Adding a New Image

1. Create a directory:
   ```bash
   images/<image-name>/
   ```

2. Add a Dockerfile following repo conventions

3. Register the image in:
   ```text
   .vscode/images.json
   ```

4. Commit and push to `develop`

CI will automatically discover and build the image.

### Modifying an Existing Image

- Keep install logic in shared scripts when possible
- Avoid image-specific CI logic
- Ensure lint targets pass

---

## 🧪 Local Builds & Testing

### Lint Only

```bash
docker build --target lint -f images/<image>/Dockerfile .
```

### Develop Image

```bash
docker build --target develop -t <image>:dev -f images/<image>/Dockerfile .
```

### Production Image

```bash
docker build -t <image>:prod -f images/<image>/Dockerfile .
```

---

## ⚠️ Common Pitfalls

- Trusting GitHub’s ahead/behind counts instead of inspecting commits
- Forgetting to register images in `.vscode/images.json`
- Breaking shared install scripts for one image
- Ignoring lint failures during local testing

If in doubt, inspect real diffs:

```bash
git log --oneline origin/main..origin/develop
```

---

> **Strict rules exist to protect downstream users.**
> If something feels inconvenient, it is usually preventing a larger failure.

