# Podman HTTPS→HTTP Pivot for localhost:5000

## Session: 2026-07-11 — "I need to be able to upload docker images to the local docker registry"

### Environment
- Host: Ubuntu 24.04 (Noble), machine `emc`
- Docker 28.4.0 (Community)
- Podman 1.33.7 (via buildah 1.33.7)
- k3s v1.35.4+k3s1 on single node
- Local registry: `registry:2` container (`kairos-registry`) bound to `127.0.0.1:5000→5000`
- Docker daemon insecure registries: `127.0.0.0/8` (configured)

### Problem
`podman push localhost:5000/myimage:latest` fails:
```
Error: trying to reuse blob sha256:... at destination: pinging container registry localhost:5000:
Get "https://localhost:5000/v2/": http: server gave HTTP response to HTTPS client
```

Docker push works fine because the daemon has `127.0.0.0/8` as insecure registry. Podman defaults to HTTPS for all registries and has no equivalent daemon-level config — it relies on `registries.conf` TOML.

### Fix applied
Created `~/.config/containers/registries.conf`:
```toml
[[registry]]
  prefix = "localhost:5000"
  location = "localhost:5000"
  insecure = true
```

**Note:** Initial attempt without `location` failed with:
```
Error: getting registries: loading registries configuration "/home/swe/.config/containers/registries.conf":
invalid condition: location is unset and prefix is not in the format: *.example.com
```
The `location` field is required when `prefix` is an exact match (not a wildcard pattern).

### Verification
```bash
# Push succeeds after fix:
podman push localhost:5000/alpine:test-push
# Writing manifest to image destination

# k3s can pull from localhost:5000 (verified with test pod):
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl run test-local-registry --image=localhost:5000/hello-world --restart=Never --rm -i -n default -- /hello
# "Hello from Docker!" → image pulled from local registry
```

### Key insight
On this host, all three runtime tools (Docker, Podman, k3s/containerd) can interact with the same local registry, but each has different default security posture:
- **Docker daemon**: trusts `127.0.0.0/8` by default
- **Podman**: requires explicit `insecure = true` per-registry
- **k3s/containerd**: works without explicit config on single-node setups where registry is on the same host