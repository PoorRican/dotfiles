# computebox storage retention

Source of truth: `nix/modules/storage-retention.nix` and
`bin/cbox-storage-retention.py`, imported only by the cbox host.

## Supported capability

**Nix, Docker images and Docker build cache are preview-only.** Their public
Python actions and CLI entrypoints reject `--apply` before inventory or native
mutation, record `blocked` with the reason, and return exit status 2. There is
no unsafe override. Native generation deletion, image removal and cache-prune
execution branches have been removed; a scheduler pause alone is not the guard.

All three non-UV timers have `WantedBy = []` and their services run previews
without `--apply`. Their calendars are retained as metadata, not enabled expiry
schedules. Future Home Manager activation must not silently enable them.
Only UV retains an automatically enabled hourly timer and an apply service.
This describes the source configuration; changes require independently reviewed
selective deployment before they describe the installed immutable helper.

Automatic Nix/image expiry cannot safely enforce these custom policies with the
reviewed stock interfaces. The maintenance flock excludes other retention jobs,
not profile switch/rollback, Docker tag or hold-file writers. Re-reading state,
a no-switch request, native current-generation protection and no-force image
removal do not close the selection-to-deletion races. Do not wrap a native
profile lock around a child that must reacquire it. A supported future apply
implementation needs a separately proven enforced boundary, not a quiescence
flag or a documentation-only assumption.

## Point-in-time preview policies

- Nix: inspect only the two canonical user profile roots (`profile`,
  `home-manager`). The selector keeps the current generation, all generations
  within 30 elapsed days, one older boundary generation, the newest five IDs,
  five distinct previous closure targets where available, and all roll-forward
  generations after a rollback. Preview retained closure requisite paths and
  their availability; this is not full-content hash verification or an atomic
  profile snapshot. The root/installer profile remains untouched. The retained
  daily 04:00 calendar is disabled, and no generation roots are expired.
- Store GC: Determinate Nixd remains the sole automatic collector. Do not enable
  Home Manager's global `nix.gc` timer or an extra cron collector. This helper
  never invokes store GC. Independent project environments need their own valid
  GC roots; preview retention does not preserve arbitrary unrooted outputs.
- Docker images: candidates are created strictly more than 14 days ago and
  unused by EVERY container in the observed inventory. Exclude multi-tagged
  images, unknown/nonpositive ages, `*:latest`, `*:stable`, `*:rollback*`, and
  label `storage.retention=keep`. Reject non-finite `Created` timestamps;
  booleans are not timestamps. Optional holds at
  `~/.config/storage-retention/keep-images.json` must be a JSON list of literal
  IDs: `sha256:` plus 64 lowercase hexadecimal characters. Wrong schemas or
  malformed IDs fail closed, without normalization. Preview selection is not
  atomic custom tag/hold protection. The retained Sunday 05:00 calendar is
  disabled; no image-removal command is executed.
- Docker build cache: retain the reviewable command and inventory for the local
  Unix-socket `default` builder: `until=336h`, decimal-byte
  `--max-used-space 100000000000` and `--reserved-space 20000000000`, without
  `--all`. The 20 GB reserve is that command's cache-retention floor, NOT a
  filesystem-free-space guarantee or protection from other collectors;
  age/in-use exclusions may leave usage above the soft 100 GB cache target.
  The command's `--force` only suppresses confirmation, but this helper never
  executes that command. The Sunday 05:20 calendar is disabled and apply also
  fails closed pending separate backend-age investigation. On October 6, 2026,
  native prune output reported nine directly selected old records satisfying
  the 336-hour policy and 6.903 GB reclaimed. Three additional mutable
  `source.local` IDs, last used about two days earlier, disappeared outside
  that output. Their reported sizes sum to 166467 bytes, NOT measured physical
  reclaim or source-data loss. The cause remains unresolved: neither an
  explicit age-filter bypass nor source-content loss has been established.
  Existing Docker/BuildKit automatic GC remains enabled and was not
  reconfigured; it includes 48-hour local-source/cachemount/git policies and
  unaged space-pressure fallbacks. Automatic GC triggered by Buildx's size-
  capability probe is the strongest supported alternative, not a confirmed
  historical cause. Explicit size budgets do not override the direct age
  check, but do not govern mutable alias lifetime or other collectors.
  This wrapper's pause is not a freeze of daemon-owned GC. No daemon config,
  reload or restart change is part of this fix.
- UV: source calendar hourly, up to 10 minutes jitter; currently temporarily
  paused pending final review and selective deployment. Manager-owned
  `uv cache prune` only, without `--force` or `--ci`. Wait five seconds for cache
  locks. Exit status 75 requires native status 2 and the complete verified UV
  0.11.21 terminal lock-timeout diagnostic, optionally preceded by its wait
  notice. A notice alone, later prune error, ambiguous/truncated output or signal
  is a failure, not a deferral. Unused-entry deletion remains pending until
  locks release; busy jobs are not forced or interrupted.
- Worktrees: manual preservation-gated cleanup only. Birth time and latest
  modification/change evidence must be strictly more than seven days old.
  Complete source/artifact preservation, exact identity, inactivity and mount
  checks are also required. Age alone never authorizes an automated `rm`.
  No worktree/container/volume deletion timer is installed.

## Operation and evidence

The CLI previews by default:

    python3 bin/cbox-storage-retention.py nix
    python3 bin/cbox-storage-retention.py images
    python3 bin/cbox-storage-retention.py build-cache
    python3 bin/cbox-storage-retention.py uv

Only `uv --apply` is supported, and live CLI apply remains restricted to
computebox. Nix/images/build-cache apply is blocked on every host.

Latest structured results are at
`~/.local/state/storage-retention/*.latest.json`. Receipt publication uses
exclusive temporary files, file fsync, atomic replacement and directory fsync.
Before native UV execution or a preview query, an `in-progress` receipt replaces
an old success. Caught exceptions and native failures publish `failed`, with
operation phase, error, available command/stdout/stderr diagnostics and nonzero
exit status. Native signal returncodes remain raw in the receipt's `returncode`
field, but wrapper/receipt/stdout `exit_code` is normalized to `128 + signal`
(e.g. native -15 becomes CLI 143; -2 becomes 130). Signals always fail, even
with an earlier lock-wait notice. Raw native stdout/stderr and combined output
are retained unchanged. A subprocess timeout records status 124; UV mutation
may have been partial and reclaimed bytes/identities are NOT verified.
`deferred-busy` is status 75, never proof of deletion. A `completed` UV receipt
records manager success, not independently measured Btrfs physical reclaim.

An abrupt kill can leave `in-progress`, not a fresh success; it requires review.
If receipt storage is unwritable, fail before starting UV; if final publication
fails, print a structured receipt error and return nonzero. Durable publication
cannot be promised when the receipt filesystem itself fails. A temporary
`.partial.json` remnant is not a completed receipt. Always check `observed_at`,
phase and exit status rather than treating an old receipt as current evidence.
Service logs are available through `journalctl --user -u cbox-retention-<name>`.

## Deployment

Normal future deployment is the cbox Home Manager configuration. Selective
deployment must use the independently reviewed immutable helper, root it under
`~/.local/state/storage-retention/deployment-script`, and render/link only its
owned eight units without activating unrelated dirty desktop configuration.
Only the UV timer should be enabled. Nix, image and build-cache timers remain
disabled, and any manually invoked non-UV services must be previews. On
October 6, 2026, the parent confirmed all four retention services masked and
inactive (MainPID 0), and stopped/disabled the UV timer as a temporary review
pause. No active retention service or long-running UV job was interrupted.
The UV source definition remains hourly/apply; resume only after independent
final review and selective deployment. This source fix does not unmask,
activate or deploy units. Live unit names match Home Manager's future
declarative ownership.

## Tests

    TMPDIR=/home/swe/.hermes/cache/scratch python3 -B -m unittest discover -s tests -p test_cbox_storage_retention.py -v

Controller tests redirect HOME, profile symlinks, hold files and receipt state
to scratch fixtures. Native destructive boundaries and Docker responses are
mocked; no live cleanup occurs. Declarative integration tests evaluate the real
Nix module offline without activating it. Tests prove guards and preview policy,
not stock-interface atomic deletion or the unresolved backend-age mechanism.

## Storage measurement

Docker image sizes share layers and cache totals overlap image storage.
Nix/UV manager-reported bytes are not Btrfs physical reclaim. Report logical
metadata used and allocated (including DUP), device-unallocated bytes and
filesystem health independently. Filtered Btrfs balance is a separately
reviewed intervention, never an automatic retention action.
