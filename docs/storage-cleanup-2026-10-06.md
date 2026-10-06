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
The original copying command and exact physical metadata attribution per
folder were not established. A read-only follow-up audit is examining OMP's
current footprint and copy implementation; it has not changed OMP settings or
established that OMP caused the rebound.

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

Detailed pre-cleanup and diagnostic evidence is also retained in
`~/.hermes/cache/scratch/btrfs-metadata-20261005-2334/`,
`~/.hermes/cache/scratch/other-metadata-audit-20261006/` and
`~/.hermes/cache/scratch/storage-followups-20261006/`. Scratch evidence is
subject to runtime expiry; it is not a durable backup. Updated operational
lessons also remain in the local `btrfs-admin` skill.
