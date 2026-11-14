---
name: nix-flake-dotfiles-maintenance
description: "Use when maintaining multi-host Nix flakes and Home Manager dotfiles, tracing package inputs, or diagnosing evaluation and activation differences."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [nix, flakes, dotfiles, home-manager, overlays, multi-host]
    related_skills: [requesting-code-review, writing-plans]
---

# Nix Flake Dotfiles Maintenance

A shared flake connects inputs, overlays and host profiles across machines. A host-local dependency can break unrelated hosts, and a successful evaluation does not mean a generation was built, applied or is running.

| When you are… | Open |
|---|---|
| Scoping inputs, overlays, lockfile changes or proving which package a host uses | [Flake inputs and hosts](references/flake-input-proof-chain.md) |
| Tracing Hermes profile wiring or planning requested local skill snapshots | [Hermes profiles and snapshot automation](references/flake-input-proof-chain.md#hermes-profile-and-local-snapshot-automation) |
| Building or activating a generation, or diagnosing managed-file conflicts | [Activation safety](references/live-activation-safety.md) |
| Diagnosing desktop session, clipboard, i3 or Polybar integration | [Desktop integration](references/i3-keybinding-debugging.md) |
| Diagnosing editor or terminal behavior after package and configuration updates | [Editor and terminal integration](references/zellij-layout-plugin-debugging.md) |
