# mealie-hummingbird

[Mealie](https://github.com/mealie-recipes/mealie) repackaged atop [Project Hummingbird](https://hummingbird-project.io/) base images for a near-zero-CVE container image. The goal is for `ghcr.io/abyrne55/mealie-hummingbird` is a drop-in replacement for the upstream `ghcr.io/mealie-recipes/mealie` image.

GitHub Actions and Dependabot trigger daily rebuilds to capture the latest Mealie versions and base image security updates.

## Usage

```bash
podman run -d \
  --name mealie \
  -p 9925:9000 \
  -v mealie-data:/app/data \
  ghcr.io/abyrne55/mealie-hummingbird:v3
```

Then open http://localhost:9925 in your browser.

## Differences from upstream

| Feature | Upstream | Hummingbird |
|---|---|---|
| Base image | `python:3.12-slim` (Debian) | `quay.io/hummingbird/python:3.12` ("distroless") |
| PUID/PGID | Supported via gosu | Use `--user UID:GID` instead |
| Shell | bash available | No shell (distroless) |
| Entrypoint/healthcheck | bash scripts | Python scripts |
| Docker secrets (`_FILE` env vars) | Supported | Supported |

## Building locally

```bash
podman build -t mealie-hummingbird:dev \
  -f Containerfile \
  --build-arg COMMIT=$(git rev-parse HEAD) .
```

Requires `git submodule update --init` if you cloned without `--recursive`.
