---
name: rust-engineering
description: "Use for Rust workspace engineering: dependency adoption and feature unification, replacing in-house layers with crates, borrowed/zero-copy decoding and honest benchmarks, uv-built Rust extensions, CI gates, deletion refactors, and multi-crate commit boundaries."
---

# Rust engineering

Rust changes often look correct by compiling while silently changing feature sets, decode validity, state transitions, or the measured work. The references collect Cargo and serde behaviors that are easy to miss, and prompts for judging whether a dependency, optimization, gate, or cutover fits the actual workspace.

| When you are… | Open |
|---|---|
| Changing borrowed deserialization, a decode path, or its performance claim | [references/borrowed-decode-and-benchmarks.md](references/borrowed-decode-and-benchmarks.md) |
| Adopting a crate, replacing an in-house layer, or evaluating resolved dependency cost | [references/dependency-adoption.md](references/dependency-adoption.md) |
| Debugging stale Rust extensions built through a uv workspace or preserving cross-language map order | [references/uv-rust-extensions.md](references/uv-rust-extensions.md) |
| Changing workspace gates, deleting Rust surface, or splitting workspace additions | [references/workspace-gates-cutovers-and-commit-splits.md](references/workspace-gates-cutovers-and-commit-splits.md) |
