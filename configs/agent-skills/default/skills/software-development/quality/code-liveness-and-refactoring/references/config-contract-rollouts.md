# Configuration contract rollouts

Scope: compatibility risks when changing a deserialized configuration contract.

## Compatibility states

- How does each of the four old/new binary × old/new configuration combinations behave? If both mixed states fail or silently change behavior, neither sequential rollout order is safe; config and binary need a coupled transition. (src: config-schema-breaking-rollout, 2026-08-20; config-schema-removal-deploy-safety, 2026-08-19)
- What did the old binary actually default the removed field to? A removed key that had a default can silently select different behavior when omitted, even if the currently deployed file set another value. (src: config-schema-breaking-rollout, 2026-08-20; config-schema-removal-deploy-safety, 2026-08-19)
- Does parsing reject unknown fields or ignore them? Strict parsers make a removed key in an old config a startup failure; permissive parsers can silently ignore it and change behavior without an error. (src: config-schema-removal-deploy-safety, 2026-08-19)
- Is configuration content bound to the binary rollout, or can a shared mutable config change independently? Independent updates can expose old binaries to new configuration on restart; content-identified config references preserve the old pair until replacement. (src: config-schema-breaking-rollout, 2026-08-20; config-schema-removal-deploy-safety, 2026-08-19)

## Deserialization and validation traps

- In Serde, `#[serde(default)]` on a containing table field supplies a value when the whole table is absent; it does not fill a newly required inner field when the table is present. (src: serde-config-contract-drift, 2026-08-06)
- A test that constructs a config struct can pass while a shipped top-level config fails to deserialize. Does the real binary get past parsing with each shipped configuration, and does a negative control containing the old key reproduce the expected failure? (src: serde-config-contract-drift, 2026-08-06)
- Does the copied config pass full validation? A validator that reports only its first rejected key does not establish complete compatibility; a fixed iteration cap can leave later errors undiscovered. (src: config-schema-breaking-rollout, 2026-08-20; config-schema-removal-deploy-safety, 2026-08-19)
- Could a renamed key remain in deployment overlays, examples, or copyable documentation even after source fixtures change? Related cadence or rate-limit fields can also become incoherent after a schema change despite successful parsing. (src: serde-config-contract-drift, 2026-08-06)

## Serialization of optional and sealed fields

- A Pydantic spec that requires exactly one explicitly supplied optional section (checked through `model_fields_set`) breaks with plain `model_dump()`: unused `None` sections are emitted and the payload fails revalidation. Recursive `exclude_none=True` is also wrong when nested required nullable fields carry meaning (an unknown geometry, or `k=None` meaning "all"). Canonical serialization should dump all values, remove only absent top-level sections, and keep nested nulls; use the canonical JSON for transport and embedded receipts, and verify a semantic round trip with nested unknown fields and null enum or config choices, not only hash stability. (src: pydantic-canonical-dump, 2026-10)
- Adding an optional field, even one defaulting to `None`, to any Pydantic model nested in a hash-sealed record changes `model_dump`, so the stored hash of every already-published artifact stops matching its handle. This surfaced only inside the first remote training pod while all unit tests passed. A `@model_serializer(mode="wrap")` that omits the new fields when `None`, plus a test that a record without them dumps exactly the sealed key set, kept old artifacts loadable. After any schema change to a sealed model, reload each already-published artifact's metadata and compare its hash with the handle before submitting jobs. (src: sealed-schema-hash, 2026-10-04)
