# Liveness and refactor evidence

## Data and call paths

- Trace a field through wildcard projections, joins and dynamic iteration as well as named references. Distinguish reaching an intermediate artifact from surviving a downstream allowlist and being consumed.
- Tests of a helper do not establish production integration. Trace the active caller, its prerequisites and the actual arguments passed; an optional feature can be implemented but unwired.
- Distinguish source evidence, unit probes, historical receipts and current execution observations. A missing local artifact may have been written elsewhere or deleted; an empty success-only tracker establishes neither a failed attempt nor that no attempt occurred.
- For a read-only audit, record the repository root and revision, separate dirty and experimental changes from mainline, and avoid switching or stashing an active worktree. Check that observed runs match the expected workload rather than inferring completion from a similar name or count.
- Before removing a legacy directory, check other implementations for imports of shared formats or types. Repository search alone cannot rule out external consumers of a public API.

## Configuration contract rollouts

- Examine old and new binaries against old and new configurations, including defaults and behavior, not just parsing. If both mixed states fail or change behavior, neither sequential rollout order is safe; couple the transition.
- Check the old binary's actual default for a removed field: omitting the key can silently select different behavior even when the deployed configuration had set another value.
- A strict parser may reject an old key, while a permissive parser may silently ignore it. Independently mutable configuration can expose an old binary to a new configuration on restart; content-identified references can preserve the pair until replacement.
- In Serde, `#[serde(default)]` on a containing field applies when that field is absent; it does not default a missing required field inside a present table. Exercise the real binary against shipped configurations and use an obsolete-key negative control where rejection is expected. Check overlays and copyable examples as well as source fixtures; first-error-only validation may conceal further incompatibilities. Related cadence or rate-limit fields can become incoherent despite successful parsing.
- For a settings adapter, capture fixtures from the original implementation and compare explicitly set fields and serialization before effective merges and rendered output. Verify the actual merge semantics of omission, empty lists and empty mappings; independently copy inputs so one run cannot mutate the other's baseline.
- A Pydantic contract based on explicitly supplied fields can fail round-trip validation when `model_dump()` emits unused `None` sections; recursive `exclude_none=True` can also remove meaningful nested nulls. Preserve the contract's distinction between absent sections and nested nulls, and test a semantic round trip.
- Serialization changes can invalidate hashes of sealed records even when a new field defaults to `None`. Check existing sealed artifacts against their stored identities; a wrap serializer that omits new fields when `None`, with a test of the old sealed key set, can preserve compatibility.
- Qualify a distributable starter using the built wheel in clean supported interpreter environments, including extras. Generate a fresh consumer and exercise its actual lock, synchronization, fixtures and CLI; editable checkout tests can miss packaged assets. For a published wheel, compare its release tag with the intended commit and index bytes with the release artifact, then validate the actual wheel.

## Parity evidence

- Compare all observables relevant to the contract. A partial dump supports only a partial claim; use the same normalization on both sides to avoid incidental representation differences. If an identity includes a code digest, compare the relevant independent identities, output digests, membership and counts separately.
- Ensure the baseline uses the same semantic schema and mapping. When necessary, rebuild it from pre-change source with the same inputs. An old entry point that delegates to the new implementation is not an independent comparison; a controlled perturbation at the emit point can test that the comparison detects drift.
- Compare baseline specifications as well as names: state-key granularity, target statistic, shrinkage and as-of discipline can materially change a comparator.
- Check new counters missing from the baseline separately, including zero where required; do not weaken the whole comparison to accommodate them.
- After a module split, patch a dependency where the consuming function looks it up, not merely a package re-export; an import check can pass while the patch misses the function's globals.
- Compare memory and timing under equivalent conditions: worker counts, child processes, reclaimable cache and warmup can confound attribution. Interleave timing order and measure retained objects where appropriate.

## State and simplification

- If an authoritative current-state projection exists, compare it with event reconstruction at phase and terminal boundaries before substituting one for the other. Preserve meaningful absence rather than fabricating zero or an empty string, and distinguish observation time from receipt or completion time.
- Equal source revisions may need reconsideration when other conditions change; deduplication by revision or content can suppress reevaluation.
- Compare enumeration set differences and source meanings before merging taxonomies. A derived registry may be extended independently, creating split ownership. Census observed values through the classifier: changing a silent admission drop for an unknown value into a hard failure changes the contract. Classifier branch order and stable identifiers can change dispatch behavior. Check whether mutually exclusive dispatch counts sum to the admitted total on real data.
- An intermediate representation may have consumers outside the apparent round trip. A repository-only search does not establish that an exported interface is unused.
- Verify that the actual CI and validation invocation graph covers the deployment-critical components and tests: files present on disk can be absent from every pre-apply gate. Check that gate comments' issue references remain current and scripts point to existing manifest paths.
