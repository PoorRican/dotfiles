# Guarded destructive storage script pattern

Use when a user wants a destructive disk format/mount workflow, but the agent should preserve safety boundaries or hand off execution to a local terminal.

## Context

A 12TB WDC HDD needed to be formatted as a generic Btrfs nearline volume. The final layout was:

- Stable target: `/dev/disk/by-id/ata-WDC_WD120EFGX-68CPHN0_WD-B01KJZJD`
- Label/mount: `nearline-12tb` at `/mnt/nearline-12tb`
- Subvolumes: `archive`, `kairos-backups`, `research-data`
- Quotas: 4TB / 6TB / 2TB

The useful reusable pattern is not the specific disk; it is how to structure a safe destructive script.

## Guard rails to include

1. Use `/dev/disk/by-id/...`, not `/dev/sdX`, for the target.
2. Verify exact model, serial, and byte size immediately before any destructive command.
3. Print the real device path resolved by `readlink -f`.
4. Refuse to continue if the disk or any child has mountpoints.
5. For a blank-disk-only formatter, refuse to continue if child partitions already exist.
6. Show `wipefs --no-act` before destruction.
7. Require an exact typed confirmation phrase that includes the label and serial.
8. Refresh sudo credentials only after all identity checks pass.
9. Create partition, filesystem, mountpoint, subvolumes, quotas, and ownership in one linear fail-fast script.
10. Validate with `lsblk`, `findmnt`, filesystem-specific status, subvolume list, quota show, and a tiny write/read/delete smoke test.
11. If fstab is optional, make it an initial-run flag such as `--add-fstab`; do not suggest rerunning a formatter later just to add fstab.

## Example skeleton

```zsh
#!/usr/bin/env zsh
emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

DISK=/dev/disk/by-id/<stable-disk-id>
PART=${DISK}-part1
LABEL=<label>
MOUNT=/mnt/<label>
EXPECTED_MODEL=<model>
EXPECTED_SERIAL=<serial>
EXPECTED_SIZE=<bytes>

REAL_DISK="$(readlink -f "$DISK")"
MODEL="$(lsblk -dn -o MODEL "$DISK" | sed 's/[[:space:]]*$//')"
SERIAL="$(lsblk -dn -o SERIAL "$DISK" | tr -d '[:space:]')"
SIZE="$(lsblk -bdn -o SIZE "$DISK" | tr -d '[:space:]')"

[[ "$MODEL" == "$EXPECTED_MODEL" ]] || exit 1
[[ "$SERIAL" == "$EXPECTED_SERIAL" ]] || exit 1
[[ "$SIZE" == "$EXPECTED_SIZE" ]] || exit 1

if findmnt -S "$DISK" >/dev/null 2>&1 || findmnt -S "$REAL_DISK" >/dev/null 2>&1; then
  echo 'target mounted; aborting' >&2
  exit 1
fi

if lsblk -nr -o MOUNTPOINTS "$DISK" | grep -q '[^[:space:]]'; then
  echo 'target child mounted; aborting' >&2
  exit 1
fi

CHILD_COUNT="$(lsblk -nr -o NAME "$DISK" | sed '1d' | grep -c . || true)"
if (( CHILD_COUNT > 0 )); then
  echo 'child partitions exist; aborting blank-disk formatter' >&2
  exit 1
fi

sudo wipefs --no-act "$DISK" || true
printf 'Type exact confirmation: FORMAT %s %s\n' "$LABEL" "$EXPECTED_SERIAL"
read -r reply
[[ "$reply" == "FORMAT $LABEL $EXPECTED_SERIAL" ]] || exit 1

sudo -v
# destructive commands begin here
```

## Pitfall

Do not create a script that says “rerun with --add-fstab” after a successful destructive format. A successful format creates child partitions, so a guarded formatter should refuse to rerun. Either use `--add-fstab` on the initial run or provide a separate fstab-only command/script after verifying the formatted filesystem.
