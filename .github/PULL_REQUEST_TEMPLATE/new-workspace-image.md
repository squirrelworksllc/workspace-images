---
name: New Workspace Image
about: Add a brand-new workspace image under images/<name>/ and register it in the CI matrix.
---

<!--
Use this template when introducing a NEW image directory under images/.
Reminder: repo root is always the build context. Be sure you reach out to
          the repo owner FIRST to make sure they are okay with you creating 
          a new workspace image. Otherwise you may have a bad time.
-->

## New Image Overview
- **New image name:** `images/<new-image>/`
- **Final image tag(s):** `squirrelworksllc/<new-image>:<tag>` (planned)
- **Purpose / use-case:**
- **Base image / tag (and why):**
- **Upstream project (if applicable):**
- **Expected size / build time (rough):**

## Required Repo Changes
- [ ] Created `images/<new-image>/Dockerfile`
- [ ] Registered in `.vscode/images.json` (CI matrix discovery)
- [ ] Added/updated documentation (README and/or image docs)
- [ ] Confirmed build context remains repo root (`docker build ... .`)

## Dockerfile Contract (must-haves)
- [ ] `base` stage exists
- [ ] `lint` stage exists
- [ ] `build` stage exists
- [ ] `develop` target exists
- [ ] `production` target exists (default)

## Security / Supply Chain Notes
- **Downloads:** (what gets downloaded, from where, how verified?)
- **GPG / checksums used?** (yes/no + details)
- **Any credentials or private repos involved?** (should be “no”)

## Validation / Testing
### Lint (required)
```bash
docker build --target lint -f images/<new-image>/Dockerfile .
```

### Production (recommended)
```bash
docker build --target production -f images/<new-image>/Dockerfile .
```

### Smoke test (optional but helpful)
- What basic command(s) did you run inside the container to confirm it starts and core tools are present?

## Notes for Reviewers
- Any long-running steps that could time out CI?
- Any steps that assume interactive input?
- Any reason this should be excluded from default CI?

## Checklist
- [ ] I have already contacted the repo owner and received approval to create this workspace (REQUIRED)
- [ ] No secrets added to Dockerfile or scripts
- [ ] Install steps are non-interactive and reproducible
- [ ] Lint gate is green
- [ ] Naming matches repo conventions
