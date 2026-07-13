---
name: local-container-registry
description: Working with a local Docker/containerd/Podman registry at localhost:5000 — tagging, pushing, pulling, verifying, and troubleshooting cross-tool registry access (Docker ↔ Podman ↔ k3s/containerd).
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [docker, podman, k3s, containerd, registry, localhost, insecure-registry]
    related_skills: [hermes-s6-container-supervision]
---

# Local Container Registry Operations

## When to use this skill

Load this skill when:
- Pushing or pulling images to/from a local registry (`localhost:5000`)
- Podman fails to push with `"http: server gave HTTP response to HTTPS client"`
- k3s/containerd needs to pull from a local HTTP-only registry
- Verifying what's stored in a local registry (catalog, tags, manifests)
- Setting up cross-tool registry access (Docker built with `127.0.0.0/8` insecure, Podman needs explicit config, k3s needs `registries.yaml`)

## Pushing to the local registry (localhost:5000)

### Three-step workflow

```bash
# 1. Tag the image with the local registry prefix
podman tag myimage:latest localhost:5000/myimage:latest
# or
docker tag myimage:latest localhost:5000/myimage:latest

# 2. Push
podman push localhost:5000/myimage:latest
# or
docker push localhost:5000/myimage:latest

# 3. Verify it arrived
curl -s http://localhost:5000/v2/_catalog | python3 -m json.tool
curl -s http://localhost:5000/v2/myimage/tags/list | python3 -m json.tool
```

## Per-tool configuration

### Docker
Docker daemon typically has `127.0.0.0/8` as an insecure registry by default. Verify:

```bash
docker info | grep -A5 "Insecure Registries"
# Expect: 127.0.0.0/8
```

If not configured, edit the daemon config at `/etc/docker/daemon.json` (systemd) or the socket-activated equivalent. Requires `systemctl restart docker`.

### Podman
Podman tries HTTPS by default for `localhost:5000` and fails with HTTP-only registries. **Must add explicit insecure registry config.**

User-level config (no sudo, no restart needed):
```toml
# ~/.config/containers/registries.conf
[[registry]]
  prefix = "localhost:5000"
  location = "localhost:5000"
  insecure = true
```

System-level (if user-level isn't sufficient):
```toml
# /etc/containers/registries.conf.d/local-registry.conf
[[registry]]
  prefix = "localhost:5000"
  location = "localhost:5000"
  insecure = true
```

### k3s / containerd
k3s can pull from `localhost:5000` if configured via `registries.yaml`:

```yaml
# /etc/rancher/k3s/registries.yaml
mirrors:
  localhost:5000:
    endpoint:
      - "http://localhost:5000"
```

Pass via `K3S_REGISTRIES_FILE=/etc/rancher/k3s/registries.yaml` or on the k3s command line with `--registries-file`. On single-node setups where the registry runs on the same host, k3s often can pull without explicit config — but explicit config is more reliable.

## Verifying registry contents

```bash
# List all repositories
curl -s http://localhost:5000/v2/_catalog | python3 -m json.tool

# List tags for a specific image
curl -s http://localhost:5000/v2/myimage/tags/list | python3 -m json.tool

# Get manifest digest (needed for deletion)
curl -s -D- -o /dev/null \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  http://localhost:5000/v2/myimage/manifests/latest 2>/dev/null \
  | grep Docker-Content-Digest
```

## Common pitfalls

### Podman: "http: server gave HTTP response to HTTPS client"
Podman defaults to HTTPS for all registries. The fix is the `insecure = true` entry in `registries.conf`. Without it, every push/pull to `localhost:5000` fails with this TLS error.

### Podman: "invalid condition: location is unset and prefix is not in the format: *.example.com"
The `[[registry]]` TOML entry requires both `prefix` AND `location` fields. `prefix` alone is only valid for wildcard patterns like `*.example.com`. For exact-match prefixes like `localhost:5000`, you need `location = "localhost:5000"` as well.

### Registry bound to 127.0.0.1
If the registry container only binds `127.0.0.1:5000->5000`, containers on the host's network namespace can't reach it via `localhost:5000` from inside the container. The host's `localhost` is the host, not the container. On single-host k3s setups, containerd runs on the host network so `localhost:5000` works.

### Registry doesn't support manifest deletion by default
The `registry:2` image does NOT enable the `delete` API by default. You need to start the container with:
```bash
docker run -d -p 5000:5000 --restart=always \
  -e REGISTRY_STORAGE_DELETE_ENABLED=true \
  registry:2
```
Without this, `DELETE /v2/<name>/manifests/<digest>` returns 405.

### Podman user-level vs system-level config
`~/.config/containers/registries.conf` is read automatically by Podman with no restart needed. `/etc/containers/registries.conf.d/` also works but requires sudo to write. Prefer user-level when possible.