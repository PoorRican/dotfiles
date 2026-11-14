# Linux memory attribution and pressure

Use `free -h`, `swapon --show --bytes`, `zramctl`, `/proc/pressure/memory` and kernel OOM logs to distinguish allocation from reclaim stalls. `MemAvailable` is more informative about remaining capacity than free memory alone. PSI `avg10`, `avg60` and `avg300` summarize stalls over their respective time windows, not necessarily the instantaneous state. A logically full zram device can occupy less physical memory due to compression; full swap alone does not prove active stalls.

Use RSS to find candidates, then inspect `/proc/<pid>/smaps_rollup`: PSS apportions shared pages, whereas summing RSS double-counts them. Group related processes and inspect cgroup `memory.current` and membership for service or container charges that per-process attribution may miss. Trace sidecar parentage before blaming a nearby workload; ending a child may be temporary if its owner restarts it.

```bash
ps -eo pid,ppid,user,stat,%mem,rss,vsz,comm,args --sort=-rss
PID=<pid>
grep -E '^(Rss|Pss|Pss_Anon|Pss_File|Pss_Shmem|Private_Dirty|Anonymous|Swap|SwapPss):' /proc/$PID/smaps_rollup
```

Compare `Private_Dirty` and `Anonymous` with PSS when deciding whether a large allocation is private or shared. For a large cgroup charge, inspect `cgroup.procs` and descendants; container accounting can be useful when process mappings are inaccessible.

A browser renderer's OS process entry does not reliably identify a tab. Compare renderer PSS and use browser task/debug metadata where available; window titles or strings in process memory are only supporting clues.

Under actual pressure, reclaim and swapping can stall a desktop before the kernel OOM killer acts. Consider workload containment, configured proactive OOM handling, or swap changes according to the host and workload. More disk swap can extend stalls; proactive OOM can kill useful work. Btrfs swapfiles have filesystem-specific requirements, for which `btrfs filesystem mkswapfile` is designed.

If zram is already used, disk swap can be a lower-priority overflow tier. For a known-heavy job, a user scope can contain it using `MemoryHigh`, `MemoryMax`, and `MemorySwapMax`; select limits for the host and workload. `systemd-oomd` requires cgroup accounting and ManagedOOM policy, so check configuration and service state rather than assuming it is active.

## Other host failures

For an NVML driver/library mismatch after an upgrade, compare the loaded NVIDIA module version in `/proc/driver/nvidia/version` with installed userspace and check modules for the running kernel. Reloading a module stack requires releasing its GPU users and can interrupt workloads; a reboot is another disruptive option when appropriate, not a universal requirement after every upgrade.

A service MainPID may be a launcher rather than the worker or scheduler. Inspect the process tree before pausing it: stopping the wrapper alone can leave the child running. Scope signals to the intended processes and consider in-flight work and reconciliation. Stopping a process that holds a data stream open can be unsafe.

Publishing by hard-linking a temporary file to its final name generates `IN_CREATE`, not necessarily `IN_CLOSE_WRITE` or `IN_MOVED_TO` for the final name. Include the matching event, establish the watch before a race-closing directory scan, and handle queue overflow. A publication notification does not establish producer success.
