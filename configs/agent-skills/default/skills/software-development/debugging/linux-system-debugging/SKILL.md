---
name: linux-system-debugging
description: "Use for Linux authentication lockouts, device and desktop-session failures, memory pressure, block storage, and related host-level troubleshooting."
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

Linux symptoms can cross kernel, service, device, session and application boundaries. A failure in one layer does not establish which layer caused it.

| When | Reference |
|---|---|
| Diagnosing PAM lockout, screen lockers, Bluetooth, or session integration | [Authentication and devices](references/bluetooth-hyprland-rfkill-case.md) |
| Investigating disk identity, mounts, formatting or hidden block-device holders | [Block storage](references/block-storage-mount-format-case.md) |
| Investigating RAM, swap, stalls, or process and cgroup memory | [Memory attribution](references/linux-memory-attribution.md) |
| Diagnosing driver mismatches, supervised processes, or filesystem notifications | [Other host failures](references/linux-memory-attribution.md#other-host-failures) |
