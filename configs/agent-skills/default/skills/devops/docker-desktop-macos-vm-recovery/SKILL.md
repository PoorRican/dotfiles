---
name: docker-desktop-macos-vm-recovery
description: Diagnose Docker Desktop for macOS when its Linux VM disk is full, read-only or reporting I/O errors, and decide whether to preserve or reset its state.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [docker, docker-desktop, macos, recovery, troubleshooting]
---

# Docker Desktop macOS VM recovery

Docker Desktop runs Linux containers in a VM backed by a disk image. A daemon connection failure alone does not prove disk failure; I/O errors, read-only filesystem messages or no-space errors in VM logs are stronger evidence of storage trouble. Check host free space too: the VM filesystem can be full or damaged even when the host has free space. Repeated process restarts cannot repair damaged storage.

Check `docker version`, `docker context ls`, and the host and VM logs under `~/Library/Containers/com.docker.docker/Data/log/host/com.docker.backend.log`, `Data/log/vm/dockerd.log`, and `Data/log/vm/console.log`. `docker version` showing only a client does not establish that the server is healthy. Check host space with `df -h /`; if the daemon responds, `docker system df -v` helps identify usage.

The disk image is sparse: `stat -f '%z' <disk-image>` reports apparent size, while `du -sh <disk-image>` reports allocated host usage. Check Docker Desktop's configured disk location; the default may have been changed. If the daemon is unavailable, historical `GET /volumes` entries in `console.log*` may identify likely consumers, but old inventories are not current or authoritative accounting.

Consider a reset only if diagnosis points to VM disk failure or exhaustion and a less destructive recovery is unsuitable. A reset discards local VM state, including named volumes, images and containers; bind-mounted host files are separate. Explain the loss and obtain explicit approval. Preserve needed data first: when the daemon works, back up images and volumes separately; otherwise, fully stop Docker Desktop and copy the configured disk image to safe storage. Follow Docker's [backup and restore guidance](https://docs.docker.com/desktop/settings-and-maintenance/backup-and-restore/); a backup of a damaged image is not proof the data is recoverable.

After an approved reset, if the UI still fails to start, inspect for an old, stuck `com.docker.backend` process rather than assuming the new disk fixed the entire failure. Use `pgrep -af 'com.docker.backend|Docker Desktop'` and `ps -o pid,lstart,etime,command -p <pid>` to inspect it; stop a confirmed stale process only when necessary and verify it is gone. If stale IPC sockets remain after the backend has stopped, remove only `backend.sock`, `docker-api-proxy.sock`, and `docker-api-proxy-control.sock` under `~/Library/Containers/com.docker.docker/Data/` before relaunching with `open -a Docker`. The privileged `com.docker.vmnetd` helper remaining alone is not proof of a blocker. Verify recovery with `docker version` showing a server and, if appropriate, `docker ps`; a newly empty instance does not contain the old volumes.
