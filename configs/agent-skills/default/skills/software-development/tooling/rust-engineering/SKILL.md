---
name: rust-engineering
description: Use for Rust workspace changes, dependency resolution, decoding and benchmarking, native Python extensions, runtime traps, Cargo verification, or Nix/crane builds.
---

# Rust engineering

Rust workspace changes can compile while changing feature resolution, decoder validity, runtime behavior, or benchmarked work. These references cover failure modes that ordinary compilation can miss.

| When | Reference |
|---|---|
| Changing borrowed decoding or benchmarking a pipeline | [Borrowed decoding and benchmarks](references/borrowed-decode-and-benchmarks.md) |
| Adopting dependencies or replacing an in-house layer | [Dependency adoption](references/dependency-adoption.md) |
| Building or debugging Python extensions | [Python extensions](references/uv-rust-extensions.md) |
| Changing workspace gates, cutovers, Cargo caches, or investigating runtime traps | [Workspace gates, Cargo and runtime traps](references/workspace-gates-cutovers-and-commit-splits.md) |
| Building Rust workspaces with Nix and crane | [Nix and crane builds](references/nix-crane-builds.md) |
