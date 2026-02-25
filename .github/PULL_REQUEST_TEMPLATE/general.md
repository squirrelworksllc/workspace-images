---
name: General Change
about: Bugfixes, refactors, CI/tooling, docs, and other routine updates.
---

<!--
Quick rules:
- main is PR-only.
- lint / gate must pass for merges to main (and develop, if enabled).
- Keep PRs focused: one logical change-set when possible.
-->

## Summary
- **What changed?**
- **Why?**
- **Scope:** (one image / multiple images / CI tooling / docs)

## Images / Components Affected
- [ ] ubuntu-noble-dind
- [ ] ubuntu-noble-desktop
- [ ] remnux
- [ ] bitcurator5
- [ ] tools/ci (lint, scripts)
- [ ] .vscode/images.json (matrix registration)
- [ ] docs / README / other

## Risk & Impact
- **Risk Level:** (Low / Medium / High)
  - *Low: Docs, non-critical refactors, typo fixes.*
  - *Medium: Most bug fixes, feature additions to a single image.*
  - *High: Changes to core shared scripts (`src/`), base images, or CI workflows.*
- **Breaking change?** (Yes/No)
  - *If yes, please explain the impact and migration path below.*

---
## Type of Change
- [ ] Bug fix
- [ ] Refactor / cleanup (no behavior change)
- [ ] Base image / dependency update
- [ ] CI / tooling change
- [ ] Documentation only
- [ ] Breaking change (explain below)

## How This Was Tested
*Describe the validation you performed. All commands should be run from the repository root.*
```bash
# 1. Lint (Required)
docker build --target lint -f images/path/to/your/Dockerfile .

# 2. Local Build (Recommended when touching installers)
docker build -f images/path/to/your/Dockerfile .

# 3. Smoke Test (Describe any manual steps taken to verify the change)
```

## Notes for Reviewers
- **Risk areas / gotchas:**
- **Anything that might look weird but is intentional:**
- **Follow-ups / TODOs (if any):**

## Checklist
- [ ] I did not change the build context (repo root remains the build context)
- [ ] I ran the lint target locally (or understand CI will enforce it)
- [ ] CI status checks are green (or actively being addressed)
- [ ] Docs updated if behavior/usage changed

## Related Issues / Links (optional)
- Closes #
- Related:
