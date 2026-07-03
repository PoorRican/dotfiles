# Linux memory attribution quick probe

Use when the user asks what is consuming RAM/swap or which desktop/browser process is responsible for a large allocation.

## Baseline

```bash
free -h
swapon --show --bytes || true
zramctl || true
cat /proc/pressure/memory || true
```

Notes:
- `MemAvailable` matters more than `MemFree`.
- zram can be logically full but compressed to a smaller physical footprint.
- `some/full avg10/avg60/avg300` pressure values show current stalls.

## Top processes and groups

Quick first pass:

```bash
ps -eo pid,ppid,user,stat,%mem,rss,vsz,comm,args --sort=-rss | head -n 30
```

Confirm with `smaps_rollup`:

```bash
PID=<pid>
grep -E '^(Rss|Pss|Pss_Anon|Pss_File|Pss_Shmem|Shared_Clean|Shared_Dirty|Private_Clean|Private_Dirty|Anonymous|Swap|SwapPss):' /proc/$PID/smaps_rollup
```

Interpretation:
- `Pss`: proportional set size, best per-process contribution estimate.
- `Private_Dirty`: private modified pages. If close to `Pss`, the process really owns the memory.
- `Anonymous`: heap/private anonymous mappings. If close to `Pss`, suspect app heap/data structures.
- `RSS`: resident pages mapped by the process; can over-count shared libraries and shared mappings.

## Browser renderer attribution

Chromium/Vivaldi/Chrome renderer process command lines often identify only `--type=renderer` and `--renderer-client-id`. The process manager view does not reliably include tab title from the OS side.

Practical evidence ladder:
1. `smaps_rollup`: prove single-process private memory vs combined/shared overcount.
2. Sibling process list: compare that renderer to other renderer PSS values.
3. Window manager metadata: visible browser window title (`hyprctl clients -j` on Hyprland).
4. Optional heuristic: scan readable anonymous/dev-shm memory in `/proc/<pid>/mem` for repeated URL/title/domain strings. Use only as supporting evidence and state confidence.

Conclusion wording:

> This is one renderer process, not the combined browser total. Its PSS and Private_Dirty are both about N GiB, so it is mostly private heap. The strongest page clue is DOMAIN/TITLE based on repeated strings in the renderer memory plus the visible browser window title, but exact PID-to-tab mapping is not exposed by the OS unless browser debugging/task metadata is available.
