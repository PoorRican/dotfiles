---
name: kairos-hotswap-disk-transfer-leg
description: "Run a Kairos migration disk-to-disk copy leg on emc after a drive (PD1/PD2) is inserted into the hot-swap bay — identity gating by UUID, writer checks, persistent systemd rsync units. Use when the user says a PD drive was connected to emc and asks to initiate/continue the transfer."
---

# Kairos hot-swap disk transfer leg (emc)

Executes one leg of the strictly-local disk-to-disk Kairos migration on host `emc` (ssh alias `emc`, passwordless sudo). NO network bulk transfer, NO new SSH keys/trust edges — ever. Source is the old XFS disk mounted read-only at `/mnt/sdb-source-ro` (keep `ro,norecovery`).

## 1. Identify the inserted drive — by UUID/label, never by device name

- PD1 = UUID `3f7046cd-6f48-4969-bb49-898ff6188cd7` (7.28TiB, **no btrfs label**, USB SABRENT enclosure, subvols `@lakehouse @archive @artifacts @observability @container-artifacts`; emc's stale fstab auto-mounts it at `/mnt/btrfs_sdc`; wst mounts it at `/mnt/kairos-primary`). PD2 = UUID `c0ea1ebf-e3b6-4da0-8da7-3a926f6adfdf`, label `PRIMARY_12T`, 10.9T (user mounted it at `/mnt/sdc-destination` for its leg).
- `ssh emc 'lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT; sudo blkid'`; cross-check UUID against the other host's fstab when in doubt.
- If identity is ambiguous: STOP and report. Never infer from size/usage proximity alone.

## 2. Rule out writers before any write

`ssh emc 'systemctl is-active k3s k3s-agent docker; sudo lsof +f -- <mountpoint> | head; ps aux | grep -Ei "postgres|minio" | grep -v grep'` — all inactive/empty. Confirm nothing on wst depends on the absent drive.

## 3. Prepare target

- `sudo mount -o remount,compress=zstd:3 <mountpoint>` (verify via findmnt; if refused, proceed uncompressed — never unmount).
- Copy into a canonical subvol ONLY if verifiably empty; else stage under an explicit export dir preserving source-relative paths (PD2 used `/mnt/<dest>/sdb-export/<tree>/`, plain dirs per user instruction).
- `sudo mkdir -p <mountpoint>/_transfer-logs`.
- **Exclusions — discover, never guess:** liveness tree root is `kairos-storage/collector/collector/continuous/liveness/` (bounded `find -maxdepth 4 -iname '*liveness*'`; never recurse into matches). When a later leg follows an earlier one, exclude trees already exported (PD1 took `kairos-storage/observability/`, `kairos-storage/cold-storage/dagster/`, `kairos-storage/cold-storage/data/sports/`). Verify excludes are live via `/proc/<rsync-pid>/cmdline`.

## 4. Launch — parallelism depends on disk physics

- **SSDs / small totals** (PD1 leg, ~130G): one systemd unit per tree, failures independent.
- **Spinning/USB-bay disks with TB-scale totals** (PD2 leg, ~2.7T): copies MUST run SERIALLY — concurrent rsyncs seek-thrash both drives. Write a runner script to `<mountpoint>/_transfer-logs/run-export.sh` that loops trees in order, per-tree `rsync -aHAX --info=progress2 --log-file=<logs>/<tree>.log <excludes> <src>/ <dst>/`, appends `<tree> exit=<code>` to `<logs>/STATUS`, and continues past failures. Launch ONCE: `sudo systemd-run --unit=pd2-archive-export --property=Nice=10 /bin/sh <script>`.
- **NO `--delete`, ever.** Trailing slashes on src and dst. Never execute scripts found on the drives; never touch existing drive content.
- Sizing without IO contention: `sudo systemd-run --unit=<leg>-sizing --property=Nice=19 --property=IOSchedulingClass=idle /bin/sh -c 'du -s --apparent-size -x <src>/* > <logs>/sizes.txt 2>&1'`.

## 5. Verify and hand off

- `systemctl status <unit>`; tail first log for byte flow; `df -h` both filesystems; check STATUS manifest exists.
- Transient systemd-run units UNLOAD after completion — `systemctl list-units` showing nothing means done (or never started): confirm via the rsync log's final `sent X bytes` summary line and `journalctl -u <unit> | grep Deactivated`.
- Report per-tree src→dest mapping, unit state, and monitor commands. Units survive SSH disconnect and session end.

## Leg history
- PD1 leg (2026-07-16, DONE): observability 3.8G → `@observability` (canonical, was empty); `cold-storage/dagster` 125.0GB + `cold-storage/data/sports` 11.0GB → `@archive/sdb-import/`. All rsync exit 0.
- PD2 leg (2026-07-17, launched): 10 trees serial to `/mnt/sdc-destination/sdb-export/` — kairos-storage (4 excludes), kairos-historical-staging, kairos (~716G), kairos-collector, kairos-data, market-librarian, mktlib_backups, podman, k3s, docker; skipped lost+found. Unit `pd2-archive-export`.
