# Block storage script command audit

Session lesson: when producing a runnable disk-format or mount script, audit the complete command set before handoff. The user may run the script locally and will reasonably expect all prerequisites to have been checked. Missing helpers discovered one at a time (`sgdisk`, then `partprobe`) are a workflow failure even if the fix is simple.

## Pattern

1. Extract every external command the script will call, including commands hidden in optional branches such as `--add-fstab`.
2. Check live availability before saying the script is ready.
3. For preferred-but-not-essential helpers, implement verified fallbacks rather than failing late.
4. State the package that provides the preferred helper, but do not require installation if the fallback is present.
5. Syntax-check the script after patching.

## Arch examples

Preferred helper:

```bash
sgdisk
```

Arch package:

```bash
sudo pacman -S --needed gptfdisk
```

Fallback usually available via util-linux:

```bash
sfdisk --wipe always --wipe-partitions always "$DISK" <<EOF
label: gpt
unit: sectors

start=2048, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="$PARTLABEL"
EOF
```

Preferred helper:

```bash
partprobe
```

Arch package:

```bash
sudo pacman -S --needed parted
```

Fallback usually available via util-linux:

```bash
blockdev --rereadpt "$DISK"
udevadm settle
```

## Audit command shape

Avoid saying a destructive script is ready until an audit like this passes:

```bash
for c in zsh lsblk readlink sudo sfdisk blockdev udevadm mount findmnt btrfs blkid wipefs grep sed tr sleep date id rm tee systemctl; do
  printf '%-12s ' "$c"
  command -v "$c" || echo MISSING
done
```

For commands blocked by the agent runtime when mentioned literally in shell, check them via a non-shell method or ask the user to verify locally; do not encode a permanent claim that the command cannot be used generally.

## User-facing posture

If a user reports a missing command from a script you handed off:

- acknowledge the miss directly;
- audit the rest of the script immediately;
- patch the script once, not one missing command at a time;
- report both installed fallbacks and optional install commands.
