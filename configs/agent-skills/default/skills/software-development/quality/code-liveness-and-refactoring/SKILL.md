---
name: code-liveness-and-refactoring
description: "Use when deciding whether code, columns, or pipeline stages are live, dormant, or stale; assessing deserialized config-schema changes; proving refactor parity; finding duplicated taxonomies; or reviewing package and infrastructure complexity. Covers data-flow and execution evidence, compatibility states, semantic parity, and risks of overclaiming dead code or harmless cleanup."
---

# Code liveness and refactoring

A symbol reference, green test, or missing local artifact rarely answers whether behavior is live or obsolete. The references separate data reaching durable outputs from actual downstream consumption, and compatibility or parity evidence from misleading proxies. They also collect common overclaims in taxonomy consolidation and simplification reviews.

| When you are… | Open |
|---|---|
| changing a deserialized configuration contract | [references/config-contract-rollouts.md](references/config-contract-rollouts.md) |
| judging code, field, pipeline, or model-output liveness | [references/liveness-verdicts.md](references/liveness-verdicts.md) |
| proving a refactor preserves behavior or comparing state projections | [references/refactor-parity.md](references/refactor-parity.md) |
| auditing duplicate taxonomies, package complexity, or infrastructure debt | [references/simplification-and-debt-audits.md](references/simplification-and-debt-audits.md) |
