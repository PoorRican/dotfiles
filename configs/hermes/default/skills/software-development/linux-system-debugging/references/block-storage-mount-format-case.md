# Block storage mount/format case notes

Session pattern: user reported two connected-but-unmounted drives: one existing ~512GiB filesystem to mount, and one 12TB HDD to format. Prior session context contained the desired 12TB layout, but the exact user-provided typo search term (`btfrs`) returned no results.

Reusable lessons:

- When asked to search past sessions with a misspelled term, first search the exact term, then retry likely corrections if no matches are found. Report both.
- For destructive storage tasks, identify target disks with multiple stable attributes before any write: `/dev/disk/by-id`, model, serial, size, current partition/filesystem signatures, mountpoints, and current kernel-visible device nodes.
- Treat user claims like “connected” as a hypothesis. Verify kernel enumeration with `lsblk`, `/dev/disk/by-*`, `/sys/block`, USB/sysfs topology, and recent kernel storage logs before trying to mount.
- If the expected drive is not kernel-visible, do not invent a mount command as if it were available. Preserve the likely previous UUID/label/path from history, but state that reseat/rescan or cable/power checks are prerequisite.
- For existing removable/external filesystems, prefer non-destructive mount-by-UUID or label, with explicit mountpoint and ownership options where appropriate.
- For Btrfs subvolume “sizes”, clarify that Btrfs subvolumes are not partitions; use qgroup quotas if the user wants soft/hard-ish capacity policy.

Representative verification commands:

```bash
lsblk -b -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL,TRAN,ROTA
sudo blkid || true
findmnt -R /mnt /media /run/media 2>/dev/null || true
for d in /dev/disk/by-id/* /dev/disk/by-label/* /dev/disk/by-uuid/*; do [ -e "$d" ] && printf '%-70s -> %s\n' "$d" "$(readlink -f "$d")"; done | sort
for b in /sys/block/*; do dev=$(basename "$b"); printf '%s size=%s removable=%s model=%s\n' "$dev" "$(cat "$b/size" 2>/dev/null || echo '?')" "$(cat "$b/removable" 2>/dev/null || echo '?')" "$(cat "$b/device/model" 2>/dev/null | sed 's/[[:space:]]\+$//' || true)"; done
journalctl -k -b --no-pager | grep -Ei 'usb-storage|uas|SCSI disk|Direct-Access|Attached scsi|sd[a-z]:|I/O error|Synchronize Cache|Cannot enable|disconnect' | tail -n 200 || true
```

Example Btrfs layout recalled in this case:

- Label: `kairos-12tb`
- Mountpoint: `/mnt/kairos-12tb`
- Mount options: `noatime,compress=zstd:3`
- Subvolumes/quotas:
  - `os_models` — 4TB
  - `kairos-backups` — 6TB
  - `kairos-data` — 2TB

Pitfall: the user had typo/name drift between `os_models` vs `os-models`, and `kairos-data` vs `cold-storage`. Preserve and call out such conflicts rather than silently choosing names.
