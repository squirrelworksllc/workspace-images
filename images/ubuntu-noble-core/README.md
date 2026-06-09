# 🐿️ Ubuntu Noble Core (`ubuntu-noble-core`)

This directory maintains the structural configuration for the foundational `ubuntu-noble-core` base image. This project functions as our immutable upstream foundation, built directly on top of the authoritative `kasmweb/core-ubuntu-noble:1.18.0-rolling-weekly` layer. All corporate workspace variations (such as `ubuntu-noble-desktop` and `ubuntu-noble-dind`) derive their system settings from this single target.

## 🔧 Platform Provisioning & Capabilities

This core image isolates the underlying Kasm runtime requirements from user-facing application layers, embedding only the absolute primitives required for stable system orchestration:

* **Upstream Lineage:** Downstream compilation from `kasmweb/core-ubuntu-noble`.
* **Execution Context:** Complete pre-configuration of initialization scaffolding (`/dockerstartup/`) to govern session lifecycle management.
* **Permission Constraints:** Explicitly maps and locks execution security parameters to the unprivileged `kasm_user` context (UID/GID `1000`).
* **Storage Optimization:** Includes standardized baseline tooling (`00_apt_helper.sh`) while relying heavily on systemic pruning steps (`01_cleanup.sh`) to purge temporary package caches and uncompressed metadata footprints.

---

## 🏗️ Repository Architecture Context

```text
images/ubuntu-noble-core/
├── Dockerfile          # Foundation layer (FROM kasmweb/core-ubuntu-noble:1.18.0-rolling-weekly)
├── .dockerignore       # Global build-context exclusion filter
├── Dockerhub.info      # Clean overview documentation for Docker Hub
└── README.md           # This primary technical architecture document
