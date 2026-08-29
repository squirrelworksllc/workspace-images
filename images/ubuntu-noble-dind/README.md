# 🐧 Ubuntu Noble Docker-in-Docker Workspace Image (`ubuntu-noble-dind`)

This directory contains the workspace configuration and documentation for the **Ubuntu Noble "Docker in Docker" (DinD)** image. It inherits from our foundational `squirrelworksllc/ubuntu-noble-core` base image (not the upstream Kasm variant), keeping the base layer standardized across the registry.

The image is deliberately minimal: **it is `ubuntu-noble-core` plus Chromium plus the Docker / Kubernetes tooling — nothing else.** No desktop-branding module, no extra apps, no generated documentation. It inherits the Kasm core XFCE session untouched.

## 🛠️ Complete Technical Tool Manifest

### 🐳 Containerization & Orchestration
* **[Docker Engine](https://docs.docker.com/engine/)** – `docker-ce`, `docker-ce-cli`, `containerd.io` from Docker's official APT repository, configured for nested containerization.
* **[Docker Compose](https://docs.docker.com/compose/)** – v2 CLI plugin, fetched at the latest upstream release (Go binary, for cleaner vulnerability posture).
* **[Docker Buildx](https://docs.docker.com/build/)** – latest upstream release, installed as a CLI plugin.
* **[k3d](https://k3d.io/) + [kubectl](https://kubernetes.io/docs/reference/kubectl/)** – lightweight Kubernetes-in-Docker tooling for local cluster work.
* **DinD helpers** – Moby's `dind` script plus the Kasm `dockerd-entrypoint.sh`, installed to `/usr/local/bin`; SubUID/SubGID configured for rootless / nested operation. Requires the container to run **privileged**.

### 🐋 Docker daemon auto-start

`dockerd` is started **after the XFCE session comes up** — by which point Kasm has already
provisioned the container, generated its nginx proxy config and handed the live session to
the user, so the daemon's `docker0` bridge / iptables setup can't race Kasm's provisioning.

- Triggered from both `/dockerstartup/custom_startup.sh` (non-blocking; backs the launch
  into the background and returns) and an `/etc/xdg/autostart` entry. A sentinel
  (`/tmp/.dind-autostart-dockerd.done`) keeps it to one start per session.
- The launcher (`/usr/local/bin/dind-autostart-dockerd`) waits for the desktop, checks the
  container is privileged (bails quietly if not), then starts `dockerd-entrypoint.sh` via
  `sudo` and waits for `/var/run/docker.sock`. Log: `/var/log/dockerd.log`.
- `kasm-user` is in the `docker` group, so `docker` / `docker compose` work without `sudo`
  once the socket is up.
- **Toggle:** build with `--build-arg`-style `ENV DOCKERD_AUTOSTART=false` (or set it on the
  Kasm Workspace) to leave the daemon stopped and start it by hand.

### 🌐 Web Browser
* **[Chromium](https://www.chromium.org/Home)** – installed by default with a `--no-sandbox` wrapper for use inside the container. Can be skipped at build time with `SKIP_CHROMIUM=true`. (Google Chrome is **not** installed here — `INSTALL_CHROME=false`.)

---

## 🖼️ Desktop Icon

Chromium always appears in the XFCE **Applications menu**. A **Desktop** shortcut is opt-in:

| Variable | Default |
| --- | --- |
| `CHROMIUM_DESKTOP_ICON` | `false` |

Set it to `true` (via `--build-arg` or the `ENV` block) to add the shortcut.

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
