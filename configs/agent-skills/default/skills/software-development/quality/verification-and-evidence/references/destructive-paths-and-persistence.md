# Destructive paths and persistence

## Verify the target

- A destructive selector and its verifier must cover the same identities and complete population. A narrowed input scope cannot certify a broader deletion; equal counts do not establish equal sets.
- Before archive-then-delete, read back the remote content and verify size and full-content digest, then recheck source version or freshness. Missing checksums can reduce validation to length only; multipart or composite checksums are not necessarily whole-object digests.
- Compare the complete source census and per-object identities as well as content. A transport checksum proves the archive moved intact, not that the archive included every file and link. Exact hash-partitioned set comparisons can bound memory; XOR and sums are not exact set comparisons.
- A file manifest that omits ACLs, xattrs, hard-link relationships or other required metadata cannot establish their equality. Copy and verify the metadata the destination must preserve; symlink-staged copies can otherwise leave dangling links.
- Preserve a verified recovery copy and durable phase/identity evidence before destructive changes. A scheduler pause is not a freeze if manual invocations can still run. If partial deletion leaves an unverifiable copy, stop and preserve the remaining evidence.
- A post-commit check cannot roll back a deletion. Source identities and protected neighbors need revalidation before separately authorized retirement.

## Recovery and continuity

- A canary surviving the actual restart, reschedule, or recreation is evidence for that event; successful startup or writes alone are not. Compare historical state and new writes after the event.
- To test crash-resume, establish that termination did not perform a graceful save, then inspect durable state and input position. Check committed input, input arriving during absence, and received but uncommitted input against the delivery contract.
- A best-checkpoint artifact may predate the interruption, making resumed-versus-uninterrupted comparison vacuous. Compare latest durable model, optimizer, RNG, sampler, history and selection state as applicable. Serialized checkpoint hashes prove byte identity, not semantic equality across fresh serializations.
- A pin does not by itself prevent retention from expiring its underlying version. Exercise retained and expired readbacks and coordinate the pin with all retention paths.
