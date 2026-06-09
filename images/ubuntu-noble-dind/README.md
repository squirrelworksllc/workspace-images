# 🐧 Ubuntu Noble 24.04 Desktop DinD Workspace Image (`ubuntu-noble-dind`)

This directory contains the workspace configuration, installation assets, and documentation for the **Ubuntu Noble Desktop "Docker in Docker" (DinD)** image. It inherits directly from our foundational `squirrelworksllc/ubuntu-noble-core` base image rather than the upstream Kasm variant, ensuring baseline standardization across our registry.

## 🛠️ Complete Technical Tool Manifest

Below is the comprehensive listing of all software and containerization runtimes pre-baked into this workspace image.

### 🐳 Containerization Runtime (Docker in Docker)
* **Docker Engine** – Full community edition daemon setup optimized for nested containerization inside unprivileged or semi-privileged container pods.
* **Docker Compose** – Multi-container orchestration CLI plugin for local application stacking.
* **Storage Driver Context** – Configured to leverage performance-optimized storage drivers (such as `overlay2`) compatible with the host kernel namespace layers.

### 🌐 Web Browsers
* **Google Chrome** – Enterprise-stable release pre-configured with flags to bypass sandboxing restrictions typically encountered within containerized environments (`--no-sandbox` wrapper integration).

### 💼 Developer Suite
* **Visual Studio Code (VSCode)** – Integrated development environment with workspace-level permissions optimized for the `kasm_user` context (UID 1000). Pre-wired to support extension environments such as Docker and Dev Containers.

---

## 🏗️ Repository Architecture Context

```text
images/ubuntu-noble-dind/
├── Dockerfile          # Image definition layer (FROM squirrelworksllc/ubuntu-noble-core)
├── .dockerignore       # Build context safety filters
├── Dockerhub.info      # Clean overview copy-paste for Docker Hub
└── README.md           # This comprehensive documentation file
