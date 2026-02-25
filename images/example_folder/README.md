# How to Create a New Workspace Image

This folder is a template. Follow these steps to create and register a new image.

## Step 1: Copy the Template

1.  Copy this entire `example_folder` directory.
2.  Rename it to match your new image (e.g., `images/my-new-app`).

## Step 2: Customize Your Dockerfile

Open `images/<your-new-app>/Dockerfile` and customize it.

### Key Sections to Edit:

1.  **`BASE_IMAGE` and `BASE_TAG`:**
    -   Change the `ARG` values to point to your desired base image. This is usually `squirrelworksllc/ubuntu-noble-core`.

2.  **`lint` Target:**
    -   Update the path in the `lint-dockerfile.sh` command to point to your new Dockerfile.
    ```dockerfile
    # Before
    RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/example_folder/Dockerfile
    # After
    RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/my-new-app/Dockerfile
    ```

3.  **`build` Target (`INST_SCRIPTS`):**
    -   Update the `ENV INST_SCRIPTS` list to include the installer scripts your image needs. These scripts live in `src/ubuntu/install/`.

## Step 3: Register in `images.json`

Open `.vscode/images.json` and add a new entry for your image. This is how CI discovers and builds it.

-   **`key`**: A unique, short name for your image.
-   **`dockerfile`**: The path to your new Dockerfile.
-   **`repo`**: The Docker Hub repository name.
-   **`prodTags`**: An array of production tags (e.g., `["1.18.0", "latest"]`).
-   **`devTags`**: An array of development tags (e.g., `["develop"]`). Should usually be JUST "develop".
-   **`devTarget` / `lintTarget`**: The names of the multi-stage build targets for development and linting.
-   **`architectures`**: A list of platforms to build. Use `["linux/amd64"]` for amd64-only images (like `remnux`) or `["linux/amd64", "linux/arm64"]` for multi-arch.

> **Note:** There is no `prodTarget` key. By convention, the production build uses the *last stage* in the Dockerfile, which must be named `production`. This is handled automatically by the CI workflows.

### Example `images.json` Entry:

```json
{
  "key": "my-new-app",
  "dockerfile": "images/my-new-app/Dockerfile",
  "repo": "squirrelworksllc/my-new-app",
  "prodTags": ["1.18.0"],
  "devTags": ["develop"],
  "devTarget": "develop",
  "lintTarget": "lint",
  "architectures": ["linux/amd64", "linux/arm64"]
}
```

## Step 4: Test Locally

Always run the lint check from the repository root before pushing.

```bash
# Lint your new image
docker build --target lint -f images/my-new-app/Dockerfile .

# (Optional) Run a dev build using the interactive script
./.vscode/docker-build.sh
