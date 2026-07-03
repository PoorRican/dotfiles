---
name: linux-system-debugging
description: "Class-level Linux debugging workflow for authentication/PAM lockouts, desktop hardware/device stacks, and RAM/swap/CPU/process resource pressure."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [linux, debugging, pam, faillock, desktop, hardware, bluetooth, memory, swap, performance]
    related_skills: [systematic-debugging]
---

# Linux System Debugging

## Purpose

Use this umbrella skill for Linux troubleshooting where the symptom could span kernel state, services, PAM/authentication, desktop-session integration, hardware/device state, or resource pressure. It consolidates the previous narrow Linux debugging skills into one class-level playbook with labeled subsections and preserved case references.

The durable pattern is: gather live evidence first, identify the failing layer, make the smallest scoped change, and verify with the same signal that proved the failure.

## When to use

Use for prompts such as:

- Password, sudo, TTY, SSH, display-manager, screen-locker, PAM, or `faillock` failures.
- Bluetooth, audio, input, networking, display, power, rfkill, GUI manager, Hyprland/WM, or desktop hardware integration failures.
- RAM, swap, zram, CPU, disk/process pressure, browser/Electron renderer, service/container/user-slice resource attribution.
- A Linux desktop/server feels slow, locked out, or has a device that works partially through CLI/kernel state but fails through GUI/session state.

For pure package-management/AUR setup or repair, use `arch-aur-package-management`; for local Parquet/SQLite dataset inspection, use `local-columnar-data-inspection`.

## Universal debugging posture

1. **Use live tools for system state.** Never answer from memory for OS, processes, resources, logs, ports, or device state.
2. **Layer the stack.** Separate kernel/device, service/daemon, persisted state, policy/auth, desktop session, and application/peripheral layers.
3. **Preserve evidence before repair.** Capture logs, counters, state files, and process metadata before resets/tuning.
4. **Avoid side effects until scoped.** PAM edits, `sudo` attempts, rfkill state writes, and process kills can change the evidence or worsen lockouts.
5. **Verify against the original symptom.** Re-run the exact failing operation or a narrow equivalent after the fix.

## Authentication, PAM, and lockouts

### Trigger symptoms

Use this section when a known password is rejected, lockout happens earlier than expected, or behavior differs across `sudo`, TTY login, SSH, display manager, screen unlock, or other PAM services.

### Core lesson: `pam_faillock` is shared by user, not by prompt

`pam_faillock` tracks failures for the user across PAM services that include it. A TTY can appear to lock out “before 3 tries” when earlier screen-locker/display-manager/sudo failures already consumed the shared tally.

Common sources include `:0` graphical sessions, `/dev/ttyN`, `sshd`, `sudo`, display managers, and screen lockers.

### Non-sudo evidence to gather first

```bash
id
whoami
hostnamectl 2>/dev/null || true
date -Is
who || true
loginctl list-sessions --no-legend 2>/dev/null || true
getent passwd "$USER" || true
passwd -S "$USER" 2>&1 || true
chage -l "$USER" 2>&1 || true
command -v faillock || true
faillock --user "$USER" 2>&1 || true
```

Read PAM and faillock config before proposing fixes. Prefer file tools where available; shell examples:

```bash
sed -n '1,200p' /etc/security/faillock.conf
sed -n '1,200p' /etc/pam.d/system-auth
sed -n '1,120p' /etc/pam.d/i3lock
sed -n '1,120p' /etc/pam.d/login
sed -n '1,120p' /etc/pam.d/lightdm
sed -n '1,120p' /etc/pam.d/sshd
```

Correlate narrowly in the journal:

```bash
journalctl -b --no-pager --since 'YYYY-MM-DD HH:MM:SS' --until 'YYYY-MM-DD HH:MM:SS' \
  -g 'faillock|pam|lightdm|i3lock|login|auth|tty|Failed|failure|incorrect|locked'

journalctl -b --no-pager \
  -g 'pam_faillock|pam_unix\(i3lock|pam_unix\(login|unix_chkpwd|FAILED LOGIN'
```

### Authentication-specific pitfalls

- Do not assume “I only tried once at the TTY” means faillock saw only one failure.
- Do not reset or tune faillock before preserving `faillock --user` and journal evidence.
- Avoid blind sudo probes in non-interactive shells; failed `sudo` can itself consume another shared failure.
- If a locker was already running when PAM config changed, compare process start time with config mtime; the running PAM conversation may still reflect old behavior.
- Prefer service-specific PAM stack changes over broad PAM weakening.
- When `:0` is involved, check keyboard layout/firmware/stuck modifiers and screen-locker/display-manager state before blaming password storage.

### Fix patterns

- If screen-locker mistakes lock the account, give that locker a PAM stack that authenticates but does not call `pam_faillock`, or otherwise exclude only that service from lockout accounting.
- If policy is too strict, tune `/etc/security/faillock.conf` (`deny`, `fail_interval`, `unlock_time`) after explaining the tradeoff.
- If replacing a locker in i3/X11, stop stale idle triggers such as `xss-lock -- ... i3lock` and use one wrapper command so manual keybindings and idle/suspend hooks switch together.

References:
- `references/screen-locker-shared-faillock-case.md`
- `references/i3-lockscreen-replacement-faillock.md`

## Desktop hardware and device integration

### Trigger symptoms

Use this section when a desktop peripheral or hardware-backed feature is present but misbehaves, especially under custom WMs/sessions. Examples: Bluetooth scan/pair/connect failures, GUI manager failures, audio/input/network/display/power devices partially working, or suspected driver/daemon/policy/persisted-state issues.

### Layered diagnosis

#### 1. Kernel/device layer

```bash
lsusb
lspci -nnk
journalctl -k -b --no-pager | grep -Ei 'bluetooth|btusb|firmware|hci|audio|input|usb|hid|drm|wifi|iwlwifi'
```

#### 2. Service/daemon layer

Bluetooth example:

```bash
systemctl status bluetooth.service --no-pager
journalctl -u bluetooth.service -b --no-pager
bluetoothctl show
bluetoothctl devices
```

#### 3. Live block/runtime state

```bash
rfkill list bluetooth
bluetoothctl power on
bluetoothctl pairable on
bluetoothctl scan on
```

Interpretation:
- `PowerState: off-blocked` means check rfkill before driver/antenna theories.
- `org.bluez.Error.NotReady` during scan usually means powered off or rfkill-blocked.
- Scanning multiple nearby BLE devices with plausible RSSI is strong evidence the controller/radio path works.

#### 4. Persisted state

```bash
sudo grep -H . /var/lib/systemd/rfkill/*bluetooth* 2>/dev/null
cat /sys/class/rfkill/rfkill*/{name,type,soft,hard,state} 2>/dev/null
```

Repair only after mapping the correct rfkill device:

```bash
sudo rfkill unblock bluetooth
sudo sh -c 'printf 0 > /var/lib/systemd/rfkill/<bluetooth-state-file>'
sudo sh -c 'printf 0 > /sys/class/rfkill/rfkillX/soft'
```

#### 5. Desktop-session integration

Custom WMs/Wayland sessions may not start GUI helpers and auth agents. Verify applets and policy agents such as `blueman-applet` and `lxqt-policykit-agent`, and import the live Wayland/Hyprland environment when starting transient user units:

```bash
systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS PATH
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS PATH
systemd-run --user --unit=waybar-manual --collect \
  --property=Environment=DISPLAY=$DISPLAY \
  --property=Environment=WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
  --property=Environment=XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP \
  --property=Environment=XDG_SESSION_TYPE=$XDG_SESSION_TYPE \
  --property=Environment=HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE \
  /usr/bin/waybar
```

The same transient-unit pattern can start `blueman-applet` or a Polkit agent in a live Hyprland session.

#### 6. Peripheral/link layer

Only after the host stack is healthy should you diagnose individual peripheral pairing/connect state. For BLE keyboards/mice, check whether `bluetoothctl info <addr>` has fresh `RSSI:` before repeated connect attempts. No RSSI plus `le-connection-abort-by-local` often means the peripheral is not advertising or is asleep; ask the user to wake or put it into pairing mode before removing/re-pairing.

When pairing mode produces a new temporary/private address, pair immediately while visible. Do not stop scanning and then retry a stale saved address first.

Kinesis Advantage360 Pro / ZMK patterns:
- Slow profile LED means a stored bond exists; rapid LED means discoverable.
- Clear both sides: `bluetoothctl remove <addr>` on Linux and Bluetooth Clear on the keyboard/profile.
- Pair/trust/connect in one interactive `bluetoothctl --agent DisplayOnly` or `KeyboardDisplay` session.
- Verify with both `bluetoothctl info <addr>` and `/proc/bus/input/devices` containing the UHID input device.

### Device-integration pitfalls

- Do not treat GUI manager failure as proof of hardware failure.
- `polkitd` alone is insufficient; a user-session auth agent must be running to show prompts.
- Fixing live rfkill without persisted systemd-rfkill state can fail on the next reset/boot.
- Do not conclude “bad antenna” before checking scan results and RSSI under an unblocked controller.
- Do not assume stale Bluetooth addresses remain valid after keyboard reset/pairing-state changes.

References:
- `references/bluetooth-hyprland-rfkill-case.md`
- `references/hyprland-waybar-ble-mouse-case.md`

## Block storage, mounts, and destructive disk formatting

### Trigger symptoms

Use this section when the user asks to mount an existing drive, identify connected-but-unmounted disks, format a disk, create Btrfs/ZFS/ext4/XFS filesystems, set up storage mountpoints, or recover a previously discussed disk layout from past sessions.

### Core workflow

1. **Recall prior intent when requested.** If the user references an earlier storage plan, search past sessions before acting. If their requested search term is misspelled or produces no hits, search it exactly first, then retry likely corrections and report both results.
2. **Inventory live kernel state before mount/format.** Capture `lsblk`, `blkid`, `/dev/disk/by-id`, `/dev/disk/by-label`, `/sys/block`, current mounts, and relevant kernel storage logs. User statements like “the drive is connected” are hypotheses until the kernel enumerates the device.
3. **Identify targets by stable attributes.** Before any write, confirm device path plus model, serial, size, existing filesystem/signatures, partition table, and mountpoints. Prefer `/dev/disk/by-id` for durable references in instructions.
4. **Separate non-destructive mount from destructive format.** Mount existing filesystems by UUID/label with explicit mountpoint and options. Do not proceed to formatting until the destructive target is unambiguous.
5. **Audit every command before handing off a runnable script.** Do not assume helpers such as `sgdisk` or `partprobe` are installed. For each command the script will call, check `command -v` (or otherwise verify availability) before presenting the script as runnable. If a preferred helper is missing, either install it explicitly or code a verified fallback and mention the package that provides the preferred helper.
6. **Prefer fallback primitives for partition-table refresh and GPT creation.** On Arch/minimal systems, `sgdisk` comes from `gptfdisk` and `partprobe` comes from `parted`; both may be absent. `sfdisk` and `blockdev --rereadpt` are util-linux fallbacks that are often already present. Verify availability live before relying on either path.
7. **For Btrfs subvolume sizing, use quotas.** Btrfs subvolumes are not fixed-size partitions; use qgroup limits when the user wants 4TB/6TB/2TB-style capacity policies. Call out any naming conflicts before creating subvolumes.
8. **If an expected disk is missing, stop at prerequisites.** Preserve likely previous UUID/label/path from history, but do not pretend it can be mounted. Ask the user to check cable/power/reseat or rescan only when you have sudo and the bus supports it.
9. **Verify with the same evidence after changes.** Re-run `lsblk`, `findmnt`, filesystem-specific listing, quota/status commands, and a tiny write/read/delete test for newly mounted writable filesystems when appropriate.

### Useful commands

```bash
lsblk -b -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL,TRAN,ROTA
sudo blkid || true
findmnt -R /mnt /media /run/media 2>/dev/null || true
for d in /dev/disk/by-id/* /dev/disk/by-label/* /dev/disk/by-uuid/*; do [ -e "$d" ] && printf '%-70s -> %s\n' "$d" "$(readlink -f "$d")"; done | sort
for b in /sys/block/*; do dev=$(basename "$b"); printf '%s size=%s removable=%s model=%s\n' "$dev" "$(cat "$b/size" 2>/dev/null || echo '?')" "$(cat "$b/removable" 2>/dev/null || echo '?')" "$(cat "$b/device/model" 2>/dev/null | sed 's/[[:space:]]\+$//' || true)"; done
journalctl -k -b --no-pager | grep -Ei 'usb-storage|uas|SCSI disk|Direct-Access|Attached scsi|sd[a-z]:|I/O error|Synchronize Cache|Cannot enable|disconnect' | tail -n 200 || true
```

References:
- `references/block-storage-mount-format-case.md`
- `references/block-storage-script-command-audit.md`

## Resource pressure and process attribution
## Resource pressure and process attribution

### Trigger symptoms

Use this section when the user asks what is consuming RAM, swap, CPU, process table, ports, or why a Linux desktop/server feels slow.

### Principles

- For memory, `ps` RSS is only a candidate finder; confirm with PSS from `/proc/<pid>/smaps_rollup`.
- Separate allocation from pressure. High used memory or full zram may be fine if available memory and PSI are healthy.
- Report top groups and top individual processes, not just raw command dumps.
- Browser/Electron renderers need special care; OS process lists do not directly reveal tab title without debug/task metadata or heuristics.

### RAM workflow

Baseline:

```bash
free -h
swapon --show --bytes || true
zramctl || true
cat /proc/pressure/memory || true
```

Quick candidate list:

```bash
ps -eo pid,ppid,user,stat,%mem,rss,vsz,comm,args --sort=-rss | head -n 30
```

Confirm with PSS:

```bash
PID=<pid>
grep -E '^(Rss|Pss|Pss_Anon|Pss_File|Pss_Shmem|Shared_Clean|Shared_Dirty|Private_Clean|Private_Dirty|Anonymous|Swap|SwapPss):' /proc/$PID/smaps_rollup
```

Group processes by normalized command family and sum PSS/RSS/swap, especially for browsers, IDEs, language servers, agents, and containers. When useful, inspect cgroups to separate user sessions, system services, Docker containers, and app scopes.

### Browser renderer attribution

For Chromium-family browsers, including Vivaldi/Chrome:

1. Confirm whether the large number is one renderer or combined usage with `smaps_rollup`.
2. List sibling renderers sorted by PSS to identify outliers.
3. Inspect window-manager metadata for visible browser title when helpful, e.g. `hyprctl clients -j`.
4. If appropriate, scan readable anonymous/dev-shm mappings for repeated URL/title/domain strings; phrase as heuristic, not guaranteed tab mapping.

### Resource answer format

1. Overall resource state: RAM, swap/zram, pressure.
2. Top groups by PSS or relevant metric.
3. Top individual outliers.
4. Interpretation: whether there is actual pressure.
5. Safe next actions.

References:
- `references/linux-memory-attribution.md`

## Verification checklist

- [ ] Captured the relevant live state and log/counter evidence before changing anything.
- [ ] Identified the failing layer instead of jumping from symptom to fix.
- [ ] Scoped any side-effecting command to the implicated service/device/process.
- [ ] Re-ran the same or equivalent evidence command after the fix.
- [ ] Reported what was proven, what remains uncertain, and the next safe action.
