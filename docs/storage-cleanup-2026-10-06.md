# Computebox storage cleanup and retention status — October 6, 2026

This is an incident record, not a deployed cleanup policy. One-off cleanup restored
allocation headroom, but metadata usage remains high and later grew again. The
retention prototype did not pass independent review and must not be treated as
production-ready.

## Changes actually made

- Removed the explicitly selected recursive copy at
  `~/kairos/kairos-data-pipeline/.worktrees/wt-20260923-173603-7c0c585`.
  The deletion command exited successfully; target absence and protected
  parent/sibling identities were checked afterward.
- Removed its separately authorized NFL-project counterpart at
  `~/kairos/kairos-data-pipeline-nfl/.worktrees/wt-20260923-173603-7c0c585`
  after complete descendant-age, preservation, identity and activity checks.
  Its physical census included 3,534,437 entries. The native deletion exited 0,
  the target was absent, and 8,311 retained unique witnesses were rehashed.
- Removed only five empty directories under `~/.omp/wt/gist-jes` using
  bottom-up `rmdir`: zero files or symlinks were deleted there. Other audited
  worktrees were retained where exact source/configuration witnesses, private
  Git history, activity or age clearance was missing. The seven-day rule applies
  to descendants and administration that removal would erase, not just the root.
- Ran bounded, low-occupancy **data** balances to restore raw device-unallocated
  space from approximately 8 GiB to 23 GiB, then stopped. No blanket balance,
  defragmentation or filesystem repair was performed.
- Expired 191 generations from the two user Nix profiles. A separate bounded
  native store GC exited 0 and reported 46,952 store paths / 32.6 GiB freed.
  All 1,580 checked protected closure paths remained available afterward; this
  was an availability check, not full-content verification of every closure.
- Removed 136 exact Docker image IDs. Before/after protected sets matched:
  186 containers, including four running containers, and 300 volumes. No
  container or volume pruning was performed.
- A builder-cache prune reported nine directly selected old records and
  6.903 GB reclaimed. Three additional young mutable `source.local` IDs
  disappeared outside that output. The historical cause remains unresolved;
  neither age-filter bypass nor source-content loss was established. Those
  three records' reported sizes totalled 166,467 bytes, not measured reclaim.
- UV pruning encountered active cache locks. No successful unused-entry cleanup
  or UV reclaim has been verified. No forced UV pruning or interruption of
  running UV jobs was authorized or performed.

An earlier diagnostic `nix-store --gc --print-dead` unexpectedly removed 13 stale
automatic GC-root links, four temporary-root files and 17 temporary store paths.
That command family was stopped and the side effects disclosed. Their contents
were not archived, so this record does not claim complete historical no-loss
proof for those diagnostic removals.

Manager-reported Nix/Docker bytes are not Btrfs physical reclaim and must not be
summed as though independent, uniquely allocated storage.

## Filesystem measurements

| Observation | Logical metadata used | Logical metadata allocated | Raw device-unallocated space |
| --- | ---: | ---: | ---: |
| Before the first recursive-copy removal | ~146.77 GiB | 169.50 GiB | ~20.00 GiB |
| After that removal | ~141.06 GiB | 175.50 GiB | ~8.00 GiB |
| After subsequent cleanup, October 6 at 03:53 MST | 134.97 GiB | 176.50 GiB | 23.00 GiB |
| Read-only check, October 6 at 07:57 MST | 141.62 GiB | 176.50 GiB | 23.00 GiB |

At the last measurement metadata was 80.24% occupied, with 34.88 GiB unused
inside allocated metadata blocks. Its DUP profile occupied 353 GiB of physical
allocation. Device error counters were zero and no balance was running. Zero
counters are not a completed clean scrub or comprehensive integrity proof.

The 6.65 GiB rebound from the post-cleanup measurement has not been attributed.
Large unlinks can themselves require new metadata allocation: reducing metadata
*used* is different from releasing block groups or restoring raw headroom.

## Metadata mechanism and OMP

The earlier complete native census counted 26,974,790 inodes under `~/.omp/wt`
across 50 immediate worktree roots. This is a dated baseline, not a current
count. The three largest protected trees accounted for 71.83% of that census.
Prior investigation also found repeatedly nested `.worktrees`, copied `.venv`
and build outputs, and distinct-inode files sharing a single data extent.

These observations support namespace/copy amplification as a major metadata
source; they do not prove pathological fragmentation of the shared file data.
The historical copying command and exact physical metadata attribution per
folder remain unestablished. The completed read-only follow-up below verifies
an amplification mechanism in the identified installed release, not the cause
of the measured rebound.

### Completed read-only follow-up

The bounded native traversal on October 6, approximately 08:40–08:48 MST,
observed an inode lower bound of **18,173,845 including `~/.omp` itself**. Only
42 of 49 immediate worktree roots obtained complete counts. The full traversal
and namespace search timed out; seven roots remained uncounted. These live
observations are not an atomic snapshot, and the lower bound must not be
compared with the older complete 26,974,790 census as though the difference
were cleanup or growth.

The largest **completed** worktree-root counts were:

| Root under `~/.omp/wt` | Inodes, including directories |
| --- | ---: |
| `kdp-step0-elevation-wt` | 7,109,836 |
| `kdp-step0.partial-incomplete-2` | 4,705,971 |
| `kdp-step0-elevation` | 2,583,653 |
| `sme-ds2-postseason` | 1,067,255 |

The separate complete census excluding `wt` counted 101,378 inodes, including
`~/.omp` and its direct files: `agent` 79,730; `plugins` 20,428; `logs` 470;
`cache` 10; `puppeteer` 2. Worktree copies dominate the observed inode footprint,
not the small top-level cache/log namespaces. Namespace counts are not physical
metadata-byte attribution; a large database also need not have a large inode
count.

The partial directory search found 974 `.venv`, 115 `.worktrees` directories
(including 99 below another `.worktrees`), 909 `target` and 1,890 `build`
directories. Each matching directory had a distinct device/inode identity.
Names do not establish disposable contents. All 49 surviving root identities
matched the earlier 50-root inventory; only the audited empty `gist-jes` root
was absent. Stable root identities do not imply stable descendant contents.

GNU `du` used its default hardlink deduplication **within each invocation**,
included directories/root entries and did not follow symlink targets. The
18,173,845 lower bound was reconstructed from nonoverlapping completed children
of the initial invocation only. Counts from separate invocations must not be
summed as a globally unique inode census. No new FIEMAP or fragmentation
measurement was performed. Individual expensive scans stayed below 180 seconds,
but the namespace audit exceeded its six-minute total target; the recorded
479-second observation window and incomplete scope are retained in evidence.

### Installed-release provenance and copy paths

The live `~/.bun/bin/omp` ELF matched the published **v18.4.8 `omp-linux-x64`**
asset by SHA-256 and size. Its digest was
`1b88f7a0da3f61edda915d836e11f63f20f2b56aeac2ddfa4ece0faa726f31c2`.
That release maps to immutable upstream commit
`717f97f4d22b3d65c4a4eef6a744255d46f4d1a6`. The adjacent globally installed
v17.2.13 package is an older source candidate, not the source baseline for this
ELF. This is published-release identity, not reproducible-build attestation.
The native cache's version/hash were checked, but its full mapped device/inode
identity and equality to the embedded release library were not established.
Active settings, process environments and actual isolation backend calls were
not inspected, and OMP/native code was not executed for this audit.

Two separate release-pinned static paths can amplify copied namespaces:

- **Isolated subagents:** `ensureIsolation` calls native `isoStart`, then
  detaches Git administration to preserve private task state. The Linux
  per-file reflink backend creates new files/directories and traverses every
  ordinary child directory; it does not prune `.worktrees`, `.venv`,
  `node_modules`, build outputs or Git-ignored paths. It reproduces symlinks
  without traversing their targets.
- **Clone-first linked Git worktrees:** `worktree.clone` defaults true in this
  release. The clone path skips only the source root's `.git`; recursive
  descent receives no skip list. Ignored artifacts are intentionally carried
  over. Setting `worktree.clone:false` for new linked worktrees would not alter
  the separate isolated-subagent `isoStart` path.

Per-file reflinks share data extents but still create independent namespace and
file metadata. Existing nested workspace/environment trees can consequently be
cloned again. This source-supported mechanism fits the observed recursive
namespaces; it is not proof of which historical operation created them, which
backend an active task resolved, pathological extent fragmentation, or OMP's
share of the 6.65 GiB metadata rebound.

The traced reflink walker also lacks a source/destination ancestry guard. A
destination beneath its source can discover its own newly created destination
and copy copies-of-copies. This is an unexercised algorithmic inference, not a
reproduced event on this host. External destination placement prevents that
self-inclusion, but not copying nested worktrees already present in the source.

Prevention directions are **recommendations only**, not implemented changes:
keep destinations outside every source checkout; consider disabling clone-first
carryover for new linked worktrees; preserve required task isolation and its
private Git state; and evaluate a Git-aware or overlay task backend only with
later authorized runtime validation. Backend selection is a preference with
fallbacks, not fail-closed enforcement. Do not enable `worktree.cleanSource`
for this purpose or replace writable isolation with shared hardlinks. A durable
upstream fix needs ancestry rejection before creation and approved exclusions
applied before descent at every depth. Ignored artifacts may contain unique
work and are not automatically disposable.

Pinned implementation references:

- [Release identity](https://github.com/can1357/oh-my-pi/releases/tag/v18.4.8)
- [Per-file reflink start and recursive traversal](https://github.com/can1357/oh-my-pi/blob/717f97f4d22b3d65c4a4eef6a744255d46f4d1a6/crates/pi-iso/src/linux_reflink.rs#L93-L233)
- [Linked-worktree clone exclusions](https://github.com/can1357/oh-my-pi/blob/717f97f4d22b3d65c4a4eef6a744255d46f4d1a6/crates/pi-vcs/src/git/mutate.rs#L650-L701)
- [Separate isolation and worktree settings](https://github.com/can1357/oh-my-pi/blob/717f97f4d22b3d65c4a4eef6a744255d46f4d1a6/packages/coding-agent/src/task/settings.ts#L23-L99)
- [Task isolation and backend fallback](https://github.com/can1357/oh-my-pi/blob/717f97f4d22b3d65c4a4eef6a744255d46f4d1a6/packages/coding-agent/src/task/worktree.ts#L538-L586)
- [Btrfs reflink explanation](https://btrfs.readthedocs.io/en/stable/Reflink.html)

The parent verifier checked 20 namespace artifact hashes, 85 source-evidence
hashes, all 50 source files against immutable Git blobs, and 61 exact source
snippets. Independent bounded upstream reads reconfirmed the release digest and
three critical implementation files. All 110 locally archived evidence members
were read back and hash-verified; raw path metadata and evidence stay outside
Git. No OMP settings, installation, worktree contents, sessions or active jobs
were changed or deleted by this follow-up.

OMP is the primary coding agent. Preserve its active work, unique outputs,
private Git administration and configuration. Do not blanket-delete `~/.omp`
or blanket-defragment reflinked data. Prevention needs the verified creator's
copy/isolation boundary, not a guessed exclusion setting.

## Retention prototype and live safety state

An initial helper and eight owned user units were selectively installed without
full Home Manager activation. Review exposed unsafe Nix rollback-floor and
Docker protected-tag/hold races. Subsequent source drafts removed those native
mutation branches, but were **not** deployed as an approved replacement.

All four custom retention services were subsequently masked and verified
inactive with MainPID 0; their timers were inactive. The original installed
helper remains behind those service masks and must not be invoked directly.
Existing Docker daemon GC was not reconfigured or disabled. Determinate Nixd
remains the existing automatic global store-GC owner; no second global
collector was added.

The five staged prototype paths remain uncommitted:

- `bin/cbox-storage-retention.py`
- `tests/test_cbox_storage_retention.py`
- `nix/modules/storage-retention.nix`
- the storage-retention import in `nix/hosts/cbox.nix`
- `docs/storage-retention.md`

The final source review passed all 42 supplied tests but failed five of 40
independent isolated probes. Remaining findings concern post-replacement
receipt-fsync status contradictions, lost native diagnostics on publication
failure, and acceptance of unverified cross-stream/stdout timeout lookalikes.
The latter is an adversarial classification gap, not an observation that UV
normally emits those streams. No further automatic fix or deployment is
approved after the two attempted fix/review cycles.

Future retention must remain explicit and independently verified:

- Worktree removal is manual, strictly older than seven elapsed days, with
  complete preservation, identity, inactivity and mount/admin checks.
- Nix's proposed keep-union includes current, 30-day history, an older boundary,
  newest five IDs, five distinct previous closures and roll-forward history.
  Preview selection does not make custom expiry atomic against rollback.
- Image candidates must be strictly older than 14 days and unused by every
  container, with tag/label/ID holds. Exact-ID removal does not make concurrent
  custom tag/hold protection atomic; unattended expiry remains unavailable.
- UV cleanup must remain manager-owned, unforced and bounded, preserving raw
  diagnostics and truthful process/receipt status. A busy deferral is not
  evidence of deletion.
- Do not activate the unapproved prototype through Home Manager or unmask its
  services until a fresh independent review approves the exact deployed bytes.

## Evidence retained locally

Raw inventories, private history checks and machine-specific receipts stay
outside Git; only this curated record is committed. Durable reports are under
`~/.local/state/storage-retention/reports/`, including:

- `20261006-cleanup-before-policy-review/`
- `20261006-nfl-copy-removal/`
- `20261006-aged-omp-audit/`
- `20261006-cache-investigation/`
- `20261006-final-review-failure/`
- `20261006-metadata-status-075749.json`
- `20261006-omp-metadata-audit/`: local-only verified evidence archive and
  member-hash manifest. The archive SHA-256 is
  `ca612b3d79aee87edf6bf33031a641d3e4e7ff7184bd5abba54d37576bd48cd9`.
  Its namespace/source report digests are respectively
  `820e1b38e1bfedf95cefc27812bf94c1be500d70c67b1443f4274d0e8b4cee58`
  and `a979803aa21e374d82a8c7519aecbce5acc0204ab9c02e6c1892f402fbf197b9`.
  The archive includes the parent verifier and receipt; it does not include
  OMP executable/native binaries or configuration/session/database bodies.

Detailed pre-cleanup and diagnostic evidence is also retained in
`~/.hermes/cache/scratch/btrfs-metadata-20261005-2334/`,
`~/.hermes/cache/scratch/other-metadata-audit-20261006/` and
`~/.hermes/cache/scratch/storage-followups-20261006/`. Scratch evidence is
subject to runtime expiry; it is not a durable backup. Updated operational
lessons also remain in the local `btrfs-admin` skill.
