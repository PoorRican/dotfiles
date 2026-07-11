# Linux desktop memory-pressure guardrails

Use this reference when a Linux desktop freezes around high RAM usage during ML training, data processing, vLLM serving, browsers, IDEs, or other large workloads.

## Symptom pattern

- RAM usage approaches ~90-95%.
- Swap is tiny or already full, often only zram.
- Desktop/compositor/terminal/browser becomes unresponsive before an OOM kill is visible.
- Kernel logs later show global OOM events, often with `Free swap = 0kB` or near-zero.
- User compares behavior to macOS offering to kill the offending application.

This is usually not primarily filesystem compression or zram compression. zram can be working correctly and still be too small for the workload. The freeze happens because processes enter direct reclaim / swap stalls while the kernel tries to find reclaimable pages. The default kernel OOM killer is a last-resort mechanism and may react only after the desktop has already stalled.

## Evidence to gather

```bash
free -h
swapon --show --bytes || true
zramctl || true
cat /proc/pressure/memory || true
journalctl -k -b --no-pager \
  -g 'Out of memory|oom|Killed process|invoked oom-killer|Free swap|hung task|blocked for more than' \
  | tail -n 200
systemctl --no-pager --type=service --all | grep -Ei 'oom|earlyoom|nohang|zram|swap' || true
systemctl status systemd-oomd.service --no-pager 2>&1 || true
sysctl vm.swappiness vm.overcommit_memory vm.overcommit_ratio vm.watermark_scale_factor vm.min_free_kbytes 2>/dev/null || true
ps -eo pid,ppid,user,stat,%mem,rss,vsz,comm,args --sort=-rss | head -n 30
```

Interpretation notes:

- `MemAvailable` matters more than raw `used` or `free` memory.
- zram `DATA` near `DISKSIZE` plus `Swap: ... 0B free` means the compressed swap tier is saturated even if the physical compressed footprint is smaller.
- PSI `some/full` values show current or recent stalls; high averages support a responsiveness problem even before OOM.
- OOM log victim names may not be the true root cause; they are what the kernel selected at that moment.

## Practical mitigation layers

Use multiple layers rather than only adding a giant swapfile.

### 1. Keep zram as first-tier swap

zram remains useful because compressed RAM swap is much faster than disk swap. Keep it higher priority than disk swap.

### 2. Add lower-priority disk/NVMe swap as overflow

On Btrfs, create swapfiles with Btrfs-aware tooling rather than naive `fallocate`/`dd` recipes:

```bash
sudo mkdir -p /swap
sudo btrfs filesystem mkswapfile --size 32G /swap/swapfile
sudo swapon --priority 10 /swap/swapfile
```

Persist with an fstab line such as:

```fstab
/swap/swapfile none swap defaults,pri=10 0 0
```

Pick the size from actual free disk space. Avoid consuming the last free space on a nearly-full root filesystem.

### 3. Add proactive OOM handling

A userspace OOM daemon can kill earlier, while the desktop is still responsive. On Arch, `earlyoom` is a simple option:

```bash
sudo pacman -S earlyoom systembus-notify
sudo systemctl enable --now earlyoom.service
```

`systemd-oomd` is another option when cgroup accounting and ManagedOOM policy are configured, but do not assume it is active just because the binary/unit exists.

### 4. Contain known-heavy training jobs with cgroups

For jobs expected to use most RAM, reserve memory for the desktop with a user scope:

```bash
systemd-run --user --scope --same-dir \
  -p MemoryHigh=48G \
  -p MemoryMax=54G \
  -p MemorySwapMax=8G \
  python train.py
```

Tune the numbers to the host. On a 60 GiB desktop, leaving roughly 6-8 GiB for the compositor/session/browser/services is a reasonable starting point.

## Tradeoffs and pitfalls

- More swap can prevent hard OOM, but if the workload actively thrashes into disk swap, training can become extremely slow.
- Adding large disk swap without proactive OOM can make freezes last longer because the system spends more time swapping instead of killing a process.
- `earlyoom` is intentionally aggressive; tell the user it may kill useful jobs and can be tuned.
- `MemoryMax` protects the desktop by sacrificing the training job when necessary.
- Do not claim Linux has no macOS-like behavior; explain that Linux has the pieces, but desktop-friendly proactive OOM/notification policy often needs to be enabled/configured.

## Answer pattern

When explaining to the user:

1. Say whether this is compression, swap saturation, late OOM, or cgroup containment.
2. Cite live evidence: RAM, swap/zram, PSI, and OOM logs.
3. Recommend a layered plan: zram first tier, disk swap overflow, proactive OOM, scoped training commands.
4. Warn that swap helps survival, not speed, and that huge swap alone can worsen stalls.
