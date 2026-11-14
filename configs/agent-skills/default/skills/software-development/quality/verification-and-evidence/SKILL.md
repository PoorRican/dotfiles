---
name: verification-and-evidence
description: "Use when assessing whether a test, gate, deployment, persistence claim, monitor, or admission policy actually works. Covers false greens, independent evidence, destructive operations, runtime proof, numerical parity, and offline verification limits."
---

# Verification and evidence

Verification connects a claim to the actual population, artifact, and behavior exercised. A green check can be vacuous, inspect the wrong object, or prove only a weaker property than the claim.

| When you are checking… | Open |
|---|---|
| test execution, gates, mutations, or independent truth | [Verification instrument trust](references/verification-instrument-trust.md) |
| deployed artifacts, runtime behavior, or API assumptions | [Deployed and runtime proof](references/deployed-and-runtime-proof.md) |
| destructive operations, copies, persistence, or recovery | [Destructive paths and persistence](references/destructive-paths-and-persistence.md) |
| coverage, observability, partitioning, or fan-out | [Coverage and observability](references/coverage-and-observability.md) |
| enforcement, signed capabilities, or admission policy CEL | [Capabilities and enforcement](references/capabilities-and-enforcement.md) |
| numerical parity, tolerances, or repeatability | [Numerical parity qualification](references/numerical-parity-qualification.md) |
