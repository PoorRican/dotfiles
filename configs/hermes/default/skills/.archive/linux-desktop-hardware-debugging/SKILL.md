---
name: linux-desktop-hardware-debugging
description: "Archived after consolidation into linux-system-debugging. Diagnose Linux desktop hardware/device integration issues across kernel, service, rfkill/state, and GUI session layers."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    archived_into: linux-system-debugging
    tags: [linux, desktop, hardware, debugging, bluetooth, rfkill, hyprland]
    related_skills: [systematic-debugging, linux-system-debugging]
---

# Linux Desktop Hardware Debugging — Archived

This skill package was consolidated into `linux-system-debugging` during the umbrella-building pass. The class-level instructions now live under the desktop hardware/device integration section of that umbrella skill.

Preserved package references:

- `references/bluetooth-hyprland-rfkill-case.md`
- `references/hyprland-waybar-ble-mouse-case.md`

## Original scope

Use when a Linux desktop peripheral or hardware-backed feature is present but behaves incorrectly, especially under a custom WM/session. Diagnose by layers: kernel/device, service/daemon, live block/runtime state, persisted state, desktop-session integration, and peripheral/link state. For Bluetooth, distinguish rfkill/power state, BlueZ service state, GUI/auth-agent failures, and peripheral pairing/bond/address problems before blaming hardware.
