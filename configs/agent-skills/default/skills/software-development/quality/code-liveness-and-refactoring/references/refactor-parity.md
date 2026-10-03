# Refactor parity

Scope: output-equivalence evidence and state-source semantics in behavior-preserving refactors.

## Parity evidence

- Which non-code identity fields and output digests, byte totals, membership, and census counts remain comparable when a top-level identity includes a code digest? (src: prechange-worktree-parity-qualification, 2026-09-14)
- Does a recorded baseline share the semantic schema or mapping version? If not, would rebuilding it from pre-change source with the same inputs separate semantic drift from the refactor? (src: prechange-worktree-parity-qualification, 2026-09-14)
- Does the comparison cover every observable relevant to the contract? A partial dump supports only a partial parity claim. Would normalizing both sides with the same encoder compare values rather than object identity or incidental float formatting? (src: byte-identity-refactor-proof, 2026-09-20)
- Are new counters absent from the golden baseline listed explicitly and checked separately (for example, expected to be zero on the unchanged path)? Globally weakening the comparison hides unrelated changes. (src: byte-identity-refactor-proof, 2026-09-20)
- Is the old comparison path independent? If the old entry point now delegates to the new implementation, old-versus-new equality is tautological. Would a controlled perturbation at the production emit point make the parity check fail? (src: prechange-worktree-parity-qualification, 2026-09-14)
- Before interpreting a missing output attribute as behavior drift, does the accessor still exist on the class? In templated SQL, doubled regex braces work only if a later `str.format` consumes them; inserted as an f-string value, they remain literal and may silently match no rows. (src: byte-identity-refactor-proof, 2026-09-20)
- A small-corpus RSS slope can reflect a change in worker count rather than per-item retention. How do parent and child processes contribute, and can retained objects be measured directly? Aggregate memory peaks may also include reclaimable scratch page cache. (src: prechange-worktree-parity-qualification, 2026-09-14)
- Are timed comparisons isolated from competing work and warming effects? Interleaved run order and an order-balanced summary reduce the chance that timing drift is mistaken for a refactor effect. (src: prechange-worktree-parity-qualification, 2026-09-14)

## Current state and event reconstruction

- If an upstream system exposes an authoritative current-state projection, is replaying its event history necessary? Reconstruction from running counters is especially suspect at phase and terminal boundaries; how do projection and reconstruction compare across those states? (src: venue-state-projection-refactor, 2026-08-06)
- Can a decision-relevant field be absent? Presence-bearing values preserve absence, whereas a default zero or empty string can fabricate a value that satisfies a consumer rule. (src: venue-state-projection-refactor, 2026-08-06)
- Can the same source revision legitimately recur while conditions change? A strict less-than dedupe permits equal revisions to be reconsidered; producer-side content deduplication can instead suppress reevaluation. (src: venue-state-projection-refactor, 2026-08-06)
- Is the timestamp the time the observed state was true, rather than local receipt or entity completion time? Freshness consumers can interpret those clocks differently. (src: venue-state-projection-refactor, 2026-08-06)
