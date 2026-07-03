---
name: linux-resource-debugging
description: "Archived after consolidation into linux-system-debugging. Diagnose Linux RAM, swap, CPU, process, and desktop/browser resource usage with PSS/cgroup-aware attribution."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    archived_into: linux-system-debugging
    tags: [linux, debugging, memory, swap, processes, performance, desktop]
    related_skills: [systematic-debugging, linux-system-debugging]
---

# Linux Resource Debugging — Archived

This skill package was consolidated into `linux-system-debugging` during the umbrella-building pass. The class-level instructions now live under the resource pressure and process attribution section of that umbrella skill.

Preserved package reference:

- `references/linux-memory-attribution.md`

## Original scope

Use when the user asks what is consuming RAM, swap, CPU, ports, process table, or why a Linux desktop/server feels slow. Baseline live state with `free`, `swapon`, `zramctl`, and PSI. Use RSS only as a candidate finder and confirm memory attribution with PSS from `/proc/<pid>/smaps_rollup`. Group processes by family and report top groups plus top individual outliers. For browser/Electron renderers, avoid claiming exact tab mappings from `ps` alone.
