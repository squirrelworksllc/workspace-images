# my-new-image

## What this image is
- Describe what the image is for.
- List major tools/features installed.

## Targets
This Dockerfile supports these targets:

- `lint` — runs hadolint + shellcheck
- `develop` — dev-flavored image
- `production` — production image (default / final stage)

## Build context rules (important)
This repo uses **repo-root** as the build context so Dockerfiles can `COPY ./src`, `./tools`, and `./common`.

That means: always build with `.` as the context.

## Build commands (from repo root)

### Lint
```bash
docker build --target lint -f images/my-new-image/Dockerfile .