# mealie-hummingbird

[Mealie](https://github.com/mealie-recipes/mealie) repackaged on [Project Hummingbird](https://www.redhat.com/en/blog/announcing-project-hummingbird) base images (Fedora distroless) for a near-zero CVE container image.

This is a drop-in replacement for the upstream `ghcr.io/mealie-recipes/mealie` image.

## Image tags

| Tag | Description |
|---|---|
| `latest` | Most recent Mealie release |
| `v3.16.0` | Specific Mealie release |
| `v3.16` | Latest patch for a minor version |
| `v3` | Latest release for a major version |
| `main` | Latest build from the main branch |

Tags are derived automatically from the Mealie submodule version. Dependabot bumps the submodule daily when new upstream releases are tagged.

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
| Base image | `python:3.12-slim` (Debian) | `quay.io/hummingbird/python:3.12` (Fedora distroless) |
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
