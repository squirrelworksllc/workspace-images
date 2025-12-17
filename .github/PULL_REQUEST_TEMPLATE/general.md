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

## Type of Change
- [ ] Bug fix
- [ ] Refactor / cleanup (no behavior change)
- [ ] Base image / dependency update
- [ ] CI / tooling change
- [ ] Documentation only
- [ ] Breaking change (explain below)

## How This Was Tested
Provide the exact commands you ran locally (or explain why you didn’t).

### Lint (required)
```bash
docker build --target lint -f images/<image>/Dockerfile .
```

### Production build (optional / recommended when touching installers)
```bash
docker build --target production -f images/<image>/Dockerfile .
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
