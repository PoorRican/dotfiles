# Destructive paths and persistence

Scope: evidence for destructive actions, exact copies, and persistence across the event that can erase state.

## Verify the target, not an adjacent property

- A destructive selector and its verifier need the same identity, scope, and completeness. Existence is not completeness; equal counts are not equal sets; HEAD metadata is not retrievability; exit 0 is not proof of the intended effect. Validation derived from a run's narrowed inputs cannot certify a broader deletion selector. (src: adjacent-verification-audit, 2026-07-27; destructive-path-safety-audit, 2026-07-27)
- For archive-then-delete, the relevant evidence is an object read-back with size and full-content digest, followed by a freshness/version check before deletion. An absent checksum field can reduce validation to length-only, which misses equal-length corruption; multipart ETags and composite SHA-256 values can encode part boundaries as well as bytes, so they are not whole-object digests. (src: destructive-path-safety-audit, 2026-07-27; object-store-transfer-byte-exact-verification, 2026-08-30)
- Byte-exact transfer evidence requires per-object hashes on both sides and a durable create-once receipt over sorted `key:size:digest` identities. Listing, object counts, size parity, and transport checksums alone do not prove content equality or source-census completeness. A BusyBox `sh` pipeline can hide a failed upstream object read without `pipefail`; read status and byte count are separate checks before hashing. (src: object-store-transfer-byte-exact-verification, 2026-08-30; mediated-verified-bulk-transfer, 2026-08-23)
- Per-object authentication and process overhead can dominate aggregate transfer verification; bandwidth-based extrapolations made before the large objects finish can badly overstate remaining time. (src: object-store-transfer-byte-exact-verification, 2026-08-30)
- Read-back evidence is stronger when bounded in memory and disk: large objects can be streamed through bounded temporary storage and hashed incrementally, with cleanup on every path. Spool size must account for the largest objects and open-file limit; freshness can change during the read-back. (src: destructive-path-safety-audit, 2026-07-27; destructive-path-verification-audit, 2026-07-27)
- Exact set comparison at scale can use deterministic hash partitioning and exact per-bucket comparisons, preserving exactness with bounded buckets. XOR can cancel duplicate pairs and sums can collide; neither is an exact-set gate. Bucket/spool design also has to respect open-file limits or metadata overhead can overwhelm the intended bound. (src: destructive-path-safety-audit, 2026-07-27; destructive-path-verification-audit, 2026-07-27; adjacent-verification-audit, 2026-07-27)

## Crash and resume state

- Before destructive work, durable recovery evidence includes expected identity and an explicit phase, published atomically with file and parent-directory fsync. If a partial remnant cannot be verified against that receipt, preserving it is safer than reconstructing from or deleting the remaining evidence. (src: destructive-path-safety-audit, 2026-07-27; adjacent-verification-audit, 2026-07-27)
- A scheduler stop is not a technical freeze if manual invocation can still run the destructive asset. A partial deletion followed by an unverifiable remote copy is an abort-and-preserve condition, not a reason to re-upload from remnants. (src: destructive-path-verification-audit, 2026-07-27)
- A transport checksum proves the archive moved intact, not that it contains every source file and symlink. Source-census equality for non-directory archive entries addresses completeness, while a verified staging copy remains the second copy at the moment of highest risk. (src: mediated-verified-bulk-transfer, 2026-08-23)
- Workstation access to two hosts does not prove host-to-host reachability; aliases may be workstation-only, and a writable child does not prove permission to create a sibling. A checksummed workstation-mediated two-leg copy avoids a standing SSH trust relationship when only the workstation holds both credentials. (src: host-op-execution-capability-preflight, 2026-08-23; mediated-verified-bulk-transfer, 2026-08-23)
- A file-reader permission denial does not establish that the shell lacks root: the reader may bypass privilege escalation. Long-running operations outlive an individual command call and need a detached supervisor plus durable progress/exit evidence. (src: host-op-execution-capability-preflight, 2026-08-23)
- Plausible file size or successful open does not establish JSON/columnar integrity. Parsed counts across structured artifacts are stronger evidence; one unreadable test file can prevent collection of an entire directory. Copies and timestamps help date suspicious corruption before attributing it to an incident. (src: post-crash-artifact-integrity-sweep, 2026-08-09)

## Persistence claims

- A canary that survives the actual stop/recreate, reschedule, or launcher-recreate path is evidence of persistence across that event. Startup, populated schema, and successful writes prove only current process state. A running database may still use an old container layer or mount configuration, and a launcher condition such as “state is not running” also matches stopped/exited objects. (src: durable-store-destructive-verification, 2026-08-08; stateful-backend-durability-proof, 2026-08-08)
- A manually applied schema is not in the deploy path; non-idempotent initialization can fail on rerun unless gated by durable state. Migration is justified for non-regenerable truth, while upstream-reconstructible projections can be rebuilt; finished-entity latches may be stale. (src: durable-store-destructive-verification, 2026-08-08)
- A post-commit check cannot roll back a transaction and may pass early when its source is already gone; it is not loss protection for a destructive action. (src: destructive-path-safety-audit, 2026-07-27)

## Resume and continuation proofs

- If an adaptive trainer exports the BEST checkpoint as its final artifact, comparing that final artifact between an uninterrupted run and a resumed run can be a vacuous recovery proof: the selected epoch may precede the crash. Compare the latest durable state recursively (optimizer, model, RNG, sampler, history, selection) instead. (src: resume-verification-lessons, 2026-09)
- For PyTorch continuation compare checkpoint state values recursively, not the SHA-256 of a fresh `torch.save(snapshot)`: pickle object sharing can make equal-valued states hash differently. Raw checkpoint hashes remain right for transport and content identity but are not semantic equivalence across fresh processes. Loader-state continuation has its own traps; see the performance skill's streaming-dataset reference. (src: resume-verification-lessons, 2026-09)

## Copying stateful data between hosts or disks

- Require an empty destination (`find <dest> -mindepth 1 -print -quit`) and copy preserving ownership, xattrs, ACLs, and hard links: `tar --numeric-owner --xattrs --acls`, or a warm `rsync -aHAX` followed by a final `--delete` delta. Record exactly which equality checks ran. (src: stateful-cold-migration, 2026-10-07)
- A sorted path/type/uid/gid/mode/size/mtime/sha manifest is not full equality: it omits ACLs, xattrs, hard links, and sub-second mtimes. Use `rsync -aHAXnc --numeric-ids` as root as a comparator, or probe each feature separately. (src: stateful-cold-migration, 2026-10-07)
- Make the source immutable (`chattr -R +i`) before the first start on the new location and keep the first-start logs. A database may "repair" what it takes for corruption by deleting later segments (seen once with a time-series database's write-ahead log); salvage from the immutable source with a disposable instance that cannot scrape or write. The immutable source is also the rollback. (src: stateful-cold-migration, 2026-10-07)
- Durability proof: capture a baseline before the move (a fixed query window saved as full JSON, an inventory of object ids to content hashes), then restart each workload and require identical history plus new data, check real panels in a browser, and for logs write per-node canary tokens, restart the log store and its shipper, and require identical lines with no replay. (src: stateful-cold-migration, 2026-10-07)

## Previewing a mutating script

- To preview a script whose writes are all `kubectl apply`, put a PATH shim ahead of `kubectl` that rewrites `apply` to `diff` (exit 0 unchanged, 1 changed, volatile fields filtered). `kubectl diff` masks Secret values, so key names show without values. Never filter the report with a pattern that drops indented lines: that hid the whole report once (2026-10-26). (src: apply-diff-shim, 2026-10-26)
- After the real run verify by readback (decode endpoint keys as text, compare credential keys as one hash), not by apply's verb: "configured" appeared although the preview said unchanged. Print only allow-listed keys, because URI-style values embed passwords. (src: apply-diff-shim, 2026-10-26)

## Symlink and destination reality checks

- `rsync -a` from a symlink-staged tree copies the links, so the destination holds dangling links to source-machine paths. For a final archive copy use `rsync -aHL`; repair an earlier mistake by deleting only confirmed remote symlink placeholders first, then rerunning. (src: staging-rsync-lessons, 2026-05)
- After transfer verify that key paths exist, are not symlinks, and that `find <dest> -type l` is empty. Check remote path spelling, owner, and writability before the heavy copy. (src: staging-rsync-lessons, 2026-05)
- Preserve raw intake trees verbatim and classify them separately from canonical outputs; classify each local database file as preserved migration artifact, canonical output, or excluded, and say why. (src: staging-rsync-lessons, 2026-05)
