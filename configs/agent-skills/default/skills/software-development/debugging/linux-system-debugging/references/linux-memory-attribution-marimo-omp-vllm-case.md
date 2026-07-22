# Memory attribution case: marimo suspicion vs OMP runners and vLLM

Use this as a pattern when the user suspects a notebook or experiment is consuming memory, especially with marimo, agent-runner processes, and Docker model servers in the same session.

## Signals from the case

Baseline showed high memory use and full zram swap, but no active PSI stalls:

```bash
free -h
swapon --show --bytes
zramctl
cat /proc/pressure/memory
vmstat 1 3
```

Key lesson: a running marimo server can be visible and still not be the culprit. Confirm with PSS before recommending notebook shutdown.

## Evidence ladder that worked

1. Gather baseline RAM/swap/PSI.
2. Use RSS only as a first-pass candidate list:
   ```bash
   ps -eo pid,ppid,user,stat,%mem,rss,vsz,comm,args --sort=-rss | head -n 40
   ```
3. Sum `Pss`, `Rss`, and `Swap` from `/proc/<pid>/smaps_rollup`, grouping by normalized process family:
   - `bun /home/swe/.bun/bin/omp` -> agent/session family
   - `/tmp/omp-python-runner/` plus project venv paths -> experiment Python runners
   - `marimo run ...` -> notebook server/kernel
   - `vllm` / `VLLM::EngineCore` -> model-serving container
   - JetBrains/PyCharm, pyright, browser, etc.
4. Check cgroup memory to find service/container/session charges that raw process grouping can obscure:
   ```bash
   find /sys/fs/cgroup -name memory.current -print
   ```
   Sort cgroups by `memory.current`; then read `cgroup.procs` for top cgroups and inspect descendant processes.
5. If Docker appears in cgroups, verify with Docker's accounting:
   ```bash
   docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}'
   docker stats --no-stream --format 'table {{.Container}}\t{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}'
   ```
6. For marimo specifically, discover the live server separately from memory attribution:
   ```bash
   bash ~/.hermes/skills/marimo-pair/scripts/discover-servers.sh 2>/dev/null || true
   pgrep -af marimo || true
   ```

## Interpretation pattern

Report in this order:

1. Overall pressure: available memory, swap/zram fullness, PSI.
2. Biggest single service/container by cgroup/Docker accounting.
3. Experiment-related groups by PSS, separating orchestration processes from child Python runners.
4. The suspected notebook's actual PSS and notebook path/URL if discoverable.
5. Safe next action by impact, e.g. stop the vLLM container first if unused, then close stale experiment/OMP sessions, rather than killing marimo if it is only a small contributor.

## Pitfalls

- Do not equate "marimo is running" with "marimo is causing memory pressure". In this case marimo was only ~177 MiB PSS while OMP/bun plus Python runners were several GiB and vLLM's Docker cgroup was ~10 GiB.
- Docker/container cgroup `memory.current` can reveal the biggest consumer even when `/proc/<pid>/smaps_rollup` is unreadable or incomplete for root/container processes.
- Full zram swap is a concern, but if PSI is 0 and `MemAvailable` is healthy, phrase it as memory is heavily used but not currently hard-stalling.
- Keep recommendations side-effect-free unless asked: provide scoped stop/kill commands instead of stopping containers or killing experiment sessions proactively.