# Integrity and reconciliation

## Consolidation

- Compare target contracts, implementation, and actual source schemas before mapping. Resolve source precedence explicitly; distinguish facts, business metadata, and operational lineage.
- Overlapping source roots are not necessarily independent or identical. Compare the complete intended overlap at the chosen row identity as a multiset, preserving duplicate counts; matching samples do not prove containment.
- If multiple input groups write the same output partition, allocate filenames uniquely across the whole run. Validate the naming on a bounded fixture and retry failed output into a fresh destination. Reconcile counts, schemas, and manifests after producers finish; report rejected inputs rather than claiming losslessness.

## Batched validation

- Partition latest-evidence windows by complete entity identity, retain conflicting latest ties, and deduplicate only fully agreeing evidence. Independent membership filters can narrow reads but do not establish tuple membership; match the full identity afterward.
- Preserve per-entity validation order, byte hash and length checks, projection comparisons, provenance, and refusal reasons. Propagate operational and authentication failures rather than treating them as empty history. Compare batch sizes one, small, and normal with independent per-entity expectations for eligibility, refusals, provenance, and digests; include batch boundaries, conflicting ties, and cross-product identity traps.
- Compare typed cells and contractually meaningful ordering, not incidental physical row order or byte-identical independently aggregated files.

## Recorded revisions

- A fresh final-state request cannot replace historical captures. Narrow retained captures by manifest and bound files, receipts, distinct bodies, and decompressed bytes; preserve originals read-only.
- Establish availability using the recorder's documented full-body receipt clock and retain timestamp precision. If converting monotonic durations, use paired clocks and reject negative elapsed durations.
- Verify retained decoded bytes against the recorded digest in its specified scope; lossy text cannot prove the original bytes. Keep receipt references and manifest fingerprint, and check extracted before-and-after payloads against original responses.
- Compare properties and relationships under stable identity, not modification timestamps alone. Inspect pagination, completeness and endpoint-specific empty-response semantics before interpreting absence as deletion; partial pages cannot establish removal of unseen entities.
