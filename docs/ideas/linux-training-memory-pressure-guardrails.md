# Linux training memory-pressure guardrails

Date: 2026-07-10

## Idea

Make the Linux desktop behave more like macOS under training-time memory pressure: avoid whole-system freezes, identify or constrain the runaway workload earlier, and preserve desktop responsiveness when ML/data jobs consume nearly all RAM.

## Problem observed

When RAM usage approaches ~95%, the system can freeze before the kernel OOM killer reacts. Current live-state notes from cbox:

- Physical RAM: ~60 GiB
- Swap: 4 GiB zram only
- zram swap was effectively full during inspection
- Kernel logs showed repeated global OOM events with `Free swap = 0kB` or near-zero
- `systemd-oomd` was present but disabled
- No proactive OOM daemon was active

This is probably not primarily caused by Btrfs compression or zram compression. zram compression was working well; the problem is that the machine runs out of reclaimable memory and swap, then stalls in direct reclaim before the late kernel OOM killer chooses a victim.

## Proposed shape

Use three layers together:

1. **Keep zram as the first swap tier**
   - zram remains useful because compressed RAM swap is much faster than disk swap.
   - Keep zram at higher priority than disk swap.

2. **Add lower-priority NVMe swap as overflow**
   - Create a Btrfs-aware swapfile on the NVMe root filesystem.
   - Suggested initial size: 32 GiB, because the root filesystem only had ~51 GiB free during inspection.
   - Example:

     ```bash
     sudo mkdir -p /swap
     sudo btrfs filesystem mkswapfile --size 32G /swap/swapfile
     sudo swapon --priority 10 /swap/swapfile
     ```

   - Persist with:

     ```fstab
     /swap/swapfile none swap defaults,pri=10 0 0
     ```

   - Existing zram priority was 100, so `pri=10` should make NVMe swap a spillover tier.

3. **Add proactive OOM / workload containment**
   - Install and enable `earlyoom` so something is killed before the desktop becomes unusable:

     ```bash
     sudo pacman -S earlyoom systembus-notify
     sudo systemctl enable --now earlyoom.service
     ```

   - For known-heavy training jobs, run them in a systemd user scope that reserves memory for the desktop:

     ```bash
     systemd-run --user --scope --same-dir \
       -p MemoryHigh=48G \
       -p MemoryMax=54G \
       -p MemorySwapMax=8G \
       python train.py
     ```

   - On a 60 GiB machine, leave roughly 6-8 GiB for the desktop/session services.

## Tradeoffs

- NVMe swap can prevent hard OOMs, but if the workload actively thrashes into disk swap, training will become very slow.
- Adding a large swapfile without proactive OOM can sometimes make freezes last longer, because the machine spends more time swapping instead of killing the offender.
- `earlyoom` is intentionally aggressive; tune or disable if it kills useful jobs too soon.
- `MemoryMax` protects the desktop, but the training process may die instead of limping forward.

## Future implementation directions

- Add a reusable wrapper script, e.g. `train-scope`, that runs commands under conservative `systemd-run --user --scope` memory limits.
- Consider Home Manager wiring for `earlyoom` package availability, while system service enablement remains host/system-level on this Arch install.
- Add a desktop notification or status-bar indicator for memory pressure, swap saturation, or PSI stalls.
- Revisit swapfile size after freeing disk space or adding a dedicated storage layout.

## Verification checklist

After implementing:

```bash
free -h
swapon --show --bytes
zramctl
cat /proc/pressure/memory
systemctl status earlyoom.service --no-pager
journalctl -k -b --no-pager -g 'Out of memory|oom|Killed process|invoked oom-killer'
```

Expected result: zram remains first-tier swap, NVMe swap appears as lower-priority overflow, and memory pressure events either remain responsive or kill the scoped training job before the desktop freezes.
