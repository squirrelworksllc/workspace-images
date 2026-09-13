# 🐧 Ubuntu Noble Docker-in-Docker Workspace Image (`ubuntu-noble-dind`)

This directory contains the workspace configuration and documentation for the **Ubuntu Noble "Docker in Docker" (DinD)** image. It inherits from our foundational `squirrelworksllc/ubuntu-noble-core` base image (not the upstream Kasm variant), keeping the base layer standardized across the registry.

The image is deliberately minimal: **`ubuntu-noble-core` plus Chromium plus the Docker / Kubernetes tooling** — no extra apps. It runs the desktop-branding step for the wallpaper and XFCE panel/menu fixes only (`GENERATE_DESKTOP_DOCS=false` skips the app-catalog documentation).

## 🛠️ Complete Technical Tool Manifest

### 🐳 Containerization & Orchestration
* **[Docker Engine](https://docs.docker.com/engine/)** – `docker-ce`, `docker-ce-cli`, `containerd.io` from Docker's official APT repository, configured for nested containerization.
* **[Docker Compose](https://docs.docker.com/compose/)** – v2 CLI plugin, fetched at the latest upstream release (Go binary, for cleaner vulnerability posture).
* **[Docker Buildx](https://docs.docker.com/build/)** – latest upstream release, installed as a CLI plugin.
* **[k3d](https://k3d.io/) + [kubectl](https://kubernetes.io/docs/reference/kubectl/)** – lightweight Kubernetes-in-Docker tooling for local cluster work.
* **DinD helpers** – Moby's `dind` script plus the Kasm `dockerd-entrypoint.sh`, installed to `/usr/local/bin`; SubUID/SubGID configured for rootless / nested operation. Requires the container to run **privileged**.

### 🐳 Starting the Docker daemon

The nested `dockerd` starts **automatically, once the desktop session is confirmed ready** —
matching Kasm's own reference DinD image (`kasmtech/workspaces-images`) rather than a
hand-rolled launcher:

- `/etc/docker/daemon.json` sets `storage-driver: fuse-overlayfs` — the kernel's default
  `overlay2` driver generally can't run on top of the container's own overlay rootfs.
- `dockerd` is registered as a `supervisord` program (`/etc/supervisor/conf.d/dockerd.conf`,
  `autostart=true`, `autorestart=true`) — logs at `/var/log/dockerd.out.log` /
  `dockerd.err.log`. If dockerd ever dies, supervisord restarts it.
- `/dockerstartup/custom_startup.sh` (installed by `dind/install_dind.sh`) waits for Kasm's
  own `filter_ready`/`desktop_ready` readiness gates, then starts (and, if it ever dies,
  restarts) `supervisord` itself. `sudo` for that one command is scoped in
  `/etc/sudoers.d/dind-supervisord`.
- `kasm-user` is in the `docker` group, so `docker` / `docker compose` work without `sudo`
  once the socket is up.
- Requires the container to run **privileged** (the Kasm Workspace setting).

### 🌐 Web Browser
* **[Chromium](https://www.chromium.org/Home)** – installed by default with a `--no-sandbox` wrapper for use inside the container. Can be skipped at build time with `SKIP_CHROMIUM=true`. (Google Chrome is **not** installed here — `INSTALL_CHROME=false`.)

---

## 🖼️ Desktop Icon

| Icon | Variable | Default |
| --- | --- | --- |
| **Chromium** | `CHROMIUM_DESKTOP_ICON` | `false` |

Chromium is always in the Applications menu regardless; the toggle only controls the Desktop
shortcut. Override via `--build-arg` or the Dockerfile `ENV` block.

---

## 🏗️ Repository Architecture Context

```text
images/ubuntu-noble-dind/
├── Dockerfile          # Image definition (FROM squirrelworksllc/ubuntu-noble-core)
├── .dockerignore       # Build context safety filters
├── Dockerhub.info      # Short overview for the Docker Hub description
└── README.md           # This file
```

Build targets (shared across all images): `lint` → `build` → `develop` / `production`.
The build context is always the **repo root**.

`dind/install_dind.sh` does deliberately overwrite `/dockerstartup/custom_startup.sh` (the
only image in this repo that does) to wire in the supervisord-managed `dockerd` described
above - this exactly matches Kasm's own reference dind image
(`kasmtech/workspaces-images`: `dind/custom_startup.sh` + `dockerd.conf` + `daemon.json`).
`desktop/install.sh` runs only for the wallpaper and XFCE panel/menu tidy-up (writes under
the user profile, `/usr/share/desktop-directories`, `/etc/xdg/menus/*-merged`).
