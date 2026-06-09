# 🐧 REMnux Malware Analysis & Forensics Workstation (`images/remnux`)

This directory contains the multi-stage, target-optimized architecture for provisioning the **REMnux Forensic Workstation**. By leveraging a SaltStack deployment model over our core, immutable system foundation (`squirrelworksllc/ubuntu-noble-core`), this image eliminates legacy OS dependencies and implements advanced malware analysis tooling cleanly into modern Kasm container runtimes.

## 🏗️ Architectural Lineage & Frameworks

Unlike legacy images pinned to Ubuntu 20.04 (Focal), this container implements a layered strategy over our standardized foundation layer:

```text
kasmweb/core-ubuntu-noble:1.18.0-rolling-weekly (Upstream Kasm Registry Layer)
   └── squirrelworksllc/ubuntu-noble-core (Our Immutable Base Layer)
         └── images/remnux/Dockerfile (This Blueprint -> REMnux Cloud Orchestration)
```

### 🛠️ Provisioning & Security Controls
*   **Multi-Stage Build Targets:** Features explicit `lint`, `build`, `develop`, and `production` targets optimized for local verification workflows and CI container execution pipelines.
*   **SaltStack Provisioning Engine:** Calls the official automated installer payload utilizing Cloud Mode (`--mode=cloud --user=kasm-user`) to establish runtime packages across Noble.
*   **Kasm PulseAudio Restoration:** Remediates upstream audio framework pruning by cleanly re-injecting the baseline system `pulseaudio` package hooks post-Salt configuration loop.
*   **UID/GID 1000 Identity Mapping:** Custom post-install orchestration merges configurations generated for transient host environments into the baseline `/home/kasm-default-profile` and `/home/kasm-user` paths with proper system permissions.
*   **OpenVEX Security Auditing:** Embeds centralized vulnerability management controls via system configurations located within `/opt/vex/vex.json` and system-wide custom ignore files (`/.trivyignore`) to guarantee accurate compliance reports.

---

## 📂 Repository Workspace Structure

```text
images/remnux/
├── Dockerfile              # Multi-stage build definition (Defines build, develop, production targets)
├── .dockerignore           # Context filters preventing host leakage into image layers
├── Dockerhub.info          # Streamlined overview documentation for Docker Hub synchronization
└── README.md               # This comprehensive architecture document
```

---

## 🚀 Local Development & Validation Workflow

Because the REMnux installation requires pulling a vast catalog of forensic packages via SaltStack and modifying low-level execution paths, local validation should always target the `develop` state inside VSCode and WSL before pushing changes downstream to the `develop` branch of the `workspace-images` repository.

### 1. Execute Local Container Compilation
Run the following build string from your local repository root folder to compile the container environment with development parameters enabled:

```bash
# Compile the local image tag targeting the multi-stage build 'develop' context
docker build \
  --target develop \
  --build-arg BASE_IMAGE="squirrelworksllc/ubuntu-noble-core" \
  --build-arg BASE_TAG="1.18.0" \
  -t squirrelworksllc/ubuntu-noble-remnux:develop \
  -f images/remnux/Dockerfile .
```

### 2. Launch Local Environment Verification
Verify that system profiles, workspace bindings, UI states, and permission sets map properly for unprivileged operation (UID 1000) by firing up a local container instance:

```bash
# Run the local analytical workspace instance to test rendering pipelines
docker run --rm -it \
  -p 6901:6901 \
  --user 1000 \
  --shm-size=512m \
  squirrelworksllc/ubuntu-noble-remnux:develop
```
