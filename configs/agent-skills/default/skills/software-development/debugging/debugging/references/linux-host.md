# Linux host troubleshooting

Scope: durable Linux authentication, device, memory, filesystem, and mount-namespace behavior that helps discriminate the failing layer.

## Authentication and devices

- `pam_faillock` tallies failures per user across PAM services that include it; GUI-locker or sudo failures can therefore consume attempts before a later TTY login. The tally and contributing services distinguish shared failures from an unexpectedly early lockout. (src: linux-system-debugging; 2026-07-10)
- A process that started before PAM configuration changed may still be using the previously loaded stack; process start time compared with the configuration modification time can distinguish this case. (src: linux-system-debugging; 2026-07-10)


- Does a GUI device manager fail while the kernel/controller path is still healthy? A GUI failure alone does not establish hardware failure; on Bluetooth, `off-blocked` or BlueZ `NotReady` points first to rfkill/controller power state, and an absent per-user PolicyKit agent can hide an authorization prompt. (src: linux-system-debugging; 2026-07-10)
- A valid Bluetooth bond does not mean a BLE peripheral is awake or currently advertising; absent live RSSI can explain a failed connection even when the controller is healthy, so the diagnosis belongs at the peripheral layer. (src: linux-system-debugging; 2026-07-10)


## Memory and pressure

- RSS counts resident pages mapped by a process and can overcount shared pages; `/proc/<pid>/smaps_rollup` PSS apportions shared memory and is a better estimate of that process's contribution. (src: linux-system-debugging; 2026-07-10)
- High used memory alone does not establish active pressure: `MemAvailable` and memory PSI indicate remaining capacity and reclaim stalls, respectively. A full logical zram tier can still have a smaller physical footprint due to compression. (src: linux-system-debugging; 2026-07-10)
- Process PSS may not expose the complete charge for containerized or otherwise grouped workloads; cgroup memory accounting can reveal aggregate usage attributed to a service or container. (src: linux-system-debugging; 2026-07-10)
- Browser renderer process memory does not directly identify a browser tab; process PSS and sibling comparison establish whether one renderer is an outlier, while strings found in process memory are only heuristic clues. (src: linux-system-debugging; 2026-07-10)


## Btrfs and swap

- Btrfs subvolumes are not fixed-size partitions; qgroup limits are the mechanism for subvolume capacity policies. (src: linux-system-debugging; 2026-07-10)
- Btrfs swapfiles have filesystem-specific constraints; Btrfs-aware support such as `btrfs filesystem mkswapfile` handles those constraints, unlike generic swapfile recipes. (src: linux-system-debugging; 2026-07-10)



## Busy block devices and hidden mounts

- Could the device's major:minor match a row in `/proc/<pid>/mountinfo`? Host-level `findmnt`, `lsof`, or `fuser` can miss another process's private mount namespace; `nsenter` exposes a candidate's namespace view. (src: hidden-mount-namespace-block-device-busy; 2026-08-24)
- Could a rootless Podman pause process retain the old filesystem after containers appear absent? An idle `catatonit -P` may hold it in a private mount namespace; an empty container/pod inventory and a specifically identified empty pause scope are the relevant evidence before stopping that scope, rather than killing blindly. (src: hidden-mount-namespace-block-device-busy; 2026-08-24)

- Before formatting a device that remains busy, do not bypass the exclusivity failure with force; identify and release its holders, then require `blockdev --rereadpt` to succeed before the destructive operation. (src: hidden-mount-namespace-block-device-busy; 2026-08-24)
- Stale container-storage configuration that still points at a retired mount can make later invocations fail or recreate state on the wrong filesystem; the obsolete reference remains a migration/removal issue. (src: hidden-mount-namespace-block-device-busy; 2026-08-24)

