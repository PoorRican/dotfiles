---
name: verification-and-evidence
description: "Use when judging whether a fix, gate, test, deployment, durability claim, partitioning change, transfer, or monitor truly works. Covers false greens and mutation evidence, committed-tree and deployed-runtime proof, destructive-path and persistence checks, automation coverage, enforcement layers, and independent truth oracles."
---

# Verification and evidence

These references focus on the distinction between what was declared, measured, installed, exercised, and independently confirmed. Reference choice follows the claim at risk, especially when a check authorizes an irreversible action.

| When you are… | Open |
|---|---|
| deciding what layer enforces a constraint, or whether a client proves capability authority | [references/capabilities-and-enforcement.md](references/capabilities-and-enforcement.md) |
| checking automation coverage, signals, or a supervised observation window | [references/coverage-and-observability.md](references/coverage-and-observability.md) |
| claiming deployed code, image behavior, runtime configuration, or rendered UI works | [references/deployed-and-runtime-proof.md](references/deployed-and-runtime-proof.md) |
| verifying deletion, transfer equality, crash recovery, or persistence | [references/destructive-paths-and-persistence.md](references/destructive-paths-and-persistence.md) |
| interpreting empty, impossible, or never-passing gates and completion evidence | [references/first-run-gates-and-completion.md](references/first-run-gates-and-completion.md) |
| measuring partitioning or fan-out behavior | [references/partitioning-and-fanout.md](references/partitioning-and-fanout.md) |
| adjudicating semantic correctness or a proposed corruption mechanism | [references/truth-oracles-and-mechanism-proof.md](references/truth-oracles-and-mechanism-proof.md) |
| checking whether a test, mutation, or gate result is genuine and reproducible | [references/verification-instrument-trust.md](references/verification-instrument-trust.md) |
