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

The nested `dockerd` is **not** started automatically — nothing runs at session login. Start
it when you need it from the **Docker in Docker** launcher (on the Desktop and under
Applications → System). It opens a held-open terminal, starts `dockerd-entrypoint.sh` via
`sudo`, waits for `/var/run/docker.sock`, and prints `docker version`.

- Launcher script: `/usr/local/bin/dind-start-docker`. Log: `/var/log/dockerd.log`.
- `sudo` is scoped to exactly one command (`/etc/sudoers.d/dind-dockerd`).
- `kasm-user` is in the `docker` group, so `docker` / `docker compose` work without `sudo`
  once the socket is up.
- Requires the container to run **privileged** (the Kasm Workspace setting). If it isn't,
  the launcher reports the failure and leaves the desktop untouched.
- `DIND_DESKTOP_ICON=false` keeps the launcher in the menu only (no Desktop icon).

### 🌐 Web Browser
* **[Chromium](https://www.chromium.org/Home)** – installed by default with a `--no-sandbox` wrapper for use inside the container. Can be skipped at build time with `SKIP_CHROMIUM=true`. (Google Chrome is **not** installed here — `INSTALL_CHROME=false`.)

---

## 🖼️ Desktop Icons

| Icon | Variable | Default |
| --- | --- | --- |
| **Docker in Docker** (starts the daemon) | `DIND_DESKTOP_ICON` | `true` |
| **Chromium** | `CHROMIUM_DESKTOP_ICON` | `false` |

Both apps are always in the Applications menu regardless; the toggle only controls the
Desktop shortcut. Override via `--build-arg` or the Dockerfile `ENV` block.

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

The `build` stage keeps `ubuntu-noble-core`'s final session prep and — unlike the version
that broke Kasm provisioning — does **not** overwrite `/dockerstartup/custom_startup.sh` or
remove `/etc/X11/xinit/Xclients`. `desktop/install.sh` runs only for the wallpaper and XFCE
panel/menu tidy-up (writes under the user profile, `/usr/share/desktop-directories`,
`/etc/xdg/menus/*-merged`). Everything else DinD adds lives in additive, non-Kasm paths
(`/usr/local/bin`, `/etc/apt`, `/etc/sudoers.d`, `/usr/share/applications`, `/etc/subuid`,
`/etc/subgid`).
