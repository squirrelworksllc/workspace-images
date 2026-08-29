# 🐧 Ubuntu Noble Docker-in-Docker Workspace Image (`ubuntu-noble-dind`)

This directory contains the workspace configuration and documentation for the **Ubuntu Noble "Docker in Docker" (DinD)** image. It inherits from our foundational `squirrelworksllc/ubuntu-noble-core` base image (not the upstream Kasm variant), keeping the base layer standardized across the registry.

Like the other images it is assembled by the **modular install registry** — the Dockerfile runs an ordered list of `src/ubuntu/install/<app>/install_*.sh` modules — but the tool set is deliberately minimal: containerization runtime plus just enough of a desktop to drive it.

## 🛠️ Complete Technical Tool Manifest

### 🐳 Containerization & Orchestration
* **[Docker Engine](https://docs.docker.com/engine/)** – `docker-ce`, `docker-ce-cli`, `containerd.io` from Docker's official APT repository, configured for nested containerization.
* **[Docker Compose](https://docs.docker.com/compose/)** – v2 CLI plugin, fetched at the latest upstream release (Go binary, for cleaner vulnerability posture).
* **[Docker Buildx](https://docs.docker.com/build/)** – latest upstream release, installed as a CLI plugin.
* **[k3d](https://k3d.io/) + [kubectl](https://kubernetes.io/docs/reference/kubectl/)** – lightweight Kubernetes-in-Docker tooling for local cluster work.
* **DinD entrypoint hooks** – Moby's dockerd-in-container helpers plus SubUID/SubGID configuration for rootless / nested operation.

### 🌐 Web Browser
* **[Chromium](https://www.chromium.org/Home)** – installed by default with a `--no-sandbox` wrapper for use inside the container. Can be skipped at build time with `SKIP_CHROMIUM=true`. (Google Chrome is **not** installed here — `INSTALL_CHROME=false`.)

### 💼 Developer Suite
* **[Visual Studio Code](https://code.visualstudio.com/)** – official `.deb` channel, with a runtime `startup.sh` hook that keeps the `kasm-user` (UID 1000) profile permissions correct across sessions. Pre-wired for the Docker / Dev Containers extension workflow.

---

## 🖼️ Desktop Icons

Every application appears in the XFCE **Applications menu**. A **Desktop** shortcut is
opt-in per app via a `<APP>_DESKTOP_ICON` environment variable in the Dockerfile. On this
image both defaults are **off**:

| Variable | Default |
| --- | --- |
| `CHROMIUM_DESKTOP_ICON` | `false` |
| `VS_CODE_DESKTOP_ICON` | `false` |

Set either to `true` (via `--build-arg` or the `ENV` block) to add the shortcut.

---

## 📚 In-Workspace Documentation

This image runs the shared `desktop/install.sh`, so it ships the generated HTML tool
catalog (`generate_desktop_docs.sh`) — reachable from **Applications → Documentation**, as a
**Documentation** desktop launcher, and at `/usr/share/squirrelworks-docs/`.

---

## 🏗️ Repository Architecture Context

```text
images/ubuntu-noble-dind/
├── Dockerfile          # Image definition (FROM squirrelworksllc/ubuntu-noble-core)
├── .dockerignore       # Build context safety filters
├── Dockerhub.info      # Short overview for the Docker Hub description
└── README.md           # This file (also baked in as the in-image Workspace Guide)
```

Build targets (shared across all images): `lint` → `build` → `develop` / `production`.
The build context is always the **repo root**. At session start Kasm runs
`/dockerstartup/custom_startup.sh`, which drives `master_startup.sh` and every per-app
`startup.sh` runtime hook.
