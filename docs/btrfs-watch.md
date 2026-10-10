# Computebox Btrfs Watch

Independent, alert-only monitoring of filesystem UUID
`12019150-ad54-405b-b8e7-ffa3a112ed02` mounted at `/`. Source configuration is
`nix/modules/btrfs-watch.nix`, imported only by cbox. The Python monitor is
`bin/cbox-btrfs-watch.py`.

Selective live deployment was verified on October 9, 2026. Only
`cbox-btrfs-watch.service` and `cbox-btrfs-watch.timer` were installed; no full
Home Manager activation was performed. The timer is enabled, with successful
automatic samples at 23:26:29 and 23:31:32 MST (303.19 seconds apart). The
second sample retained the warning-notification cooldown rather than repeating
it. State directory/file permissions were verified as 0700/0600.

The reviewed, GC-rooted unit bundle is:

    /nix/store/wkwj65g9h2bf1il8dq3p15maj1yjc7n0-cbox-btrfs-watch-deployment

Its persistent GC root is `~/.local/state/btrfs-watch/deployment`; its store
script was checked byte-for-byte against the reviewed source. All 56 owned tests
and Ruff passed. Independent review found no security or logic blockers and
exercised 30 additional scratch-local cases with both host and pinned Python.
The real warning was accepted as desktop notification ID 39. A separate delivery
test, ID 40, naturally expired and was read back from Dunst history with its
exact application, title and body. This verifies the notification path, not that
a person saw or acknowledged the real warning.

All four cleanup-prototype services remain masked/inactive. Monitor changes are
tracked separately from the unrelated retention draft; existing foreign staged
entries were preserved during selective deployment. Do not activate that draft
as part of a future full configuration switch without its separate required
review.

## Scope and limits

The monitor queries mount identity, `btrfs filesystem usage -b`, kernel metadata
reservation counters and recorded device-error counters. These queries work
without root on this host. It changes only its own bounded measurement state
and desktop notifications; it never invokes cleanup, balance, snapshots,
defragmentation, GC, OMP, or the suspended storage-retention helper. Its Nix
closure pins its Python, Btrfs, findmnt and notification dependencies.

Monitoring is early warning, not a guarantee against ENOSPC. It does not stop
writers, establish a hard reserve, eliminate recursive workspace copying, check
a complete snapshot inventory, or prove filesystem integrity. A recorded error
counter is not necessarily a new error, and zero counters are not a clean scrub.

## Conservative host policy

Every five minutes, with up to 20 seconds of jitter:

| Signal | Warning | Critical |
| --- | --- | --- |
| Logical metadata occupancy | >=85% | >=95% |
| Metadata margin after accounted reservations | <=20 GiB | <=5 GiB |
| Raw device-unallocated space | <=50 GiB | <=10 GiB |
| Recorded device errors or read-only mount | — | Any |

Positive metadata growth >=1 GiB/hour over a measured 45–75 minute span also
warns. These are deliberately conservative local policy thresholds, not Btrfs
universal failure boundaries. The reservation-adjusted margin is a pressure
indicator, not a guarantee of writable capacity. Samples are live, non-atomic.
Growth alerts require sufficient real history; first-run output cannot establish
a rate. Missing or failed queries fail visibly rather than assuming health.

State is bounded to seven days and at most 2,016 measurement points. Warning
notifications repeat at most every six hours, critical ones every hour, with
immediate escalation. A failed notification must not advance its cooldown.
Desktop alerts require a running notification server; journal evidence remains
available separately. User lingering is enabled on computebox, so an enabled
user timer can run without an interactive login, but desktop delivery cannot be
promised while no desktop notification server is available.

## Inspect and operate

    systemctl --user status cbox-btrfs-watch.timer
    systemctl --user show cbox-btrfs-watch.service -p Result -p ExecMainStatus
    journalctl --user -u cbox-btrfs-watch.service -n 10 --no-pager

Measurement state is under `~/.local/state/btrfs-watch/`. Fresh timestamps and
the service exit status matter: a state file is not an authoritative success
receipt. State publication or notification failures must return nonzero, even
if a replacement state file became visible before a directory-fsync failure.
No durability guarantee is made when the filesystem rejects writes.

A genuinely read-only manual query (no state creation or notifications):

    python3 -B ~/dotfiles/bin/cbox-btrfs-watch.py \
      --uuid 12019150-ad54-405b-b8e7-ffa3a112ed02 \
      --state-dir ~/.local/state/btrfs-watch --print-only

Tests use isolated scratch fixtures, never live cleanup:

    python3 -B -m unittest discover -s tests -p 'test_cbox_btrfs_watch*.py' -v

## Response to an alert

Inspect current allocation and growth before intervening. Raw unallocated
capacity, unused allocated data, and unused logical metadata are different
resources. Preserve metadata DUP redundancy. A separately authorized, bounded
low-occupancy data balance may restore allocation flexibility; it does not
remove live inode/directory metadata or prevent workspace-copy growth.
Preservation-gated removal of genuinely obsolete copies and fixing their creator
remain separate work. Never blanket-delete agent worktrees or enable the failed
cleanup prototype as an alert response.

## Why snapshotting is not a metadata reset

Snapshots share existing filesystem structures and file data; deleting their
source does not erase metadata needed by the surviving snapshot. COW does not
mean every historical file version is permanently retained without snapshots
or other references. Deleting identified obsolete snapshots may free their
exclusive references, but must be assessed separately. Snapshotting `/` also
does not capture the separately mounted home, log, package-cache and temporary
subvolumes in this host's layout.

A true rebuild means a verified independent backup followed by migration to a
fresh filesystem and restoration of the required current contents. That is a
separate, explicitly approved maintenance operation, not emergency metadata
cleanup. Millions of retained current files still require metadata afterward.
A same-drive snapshot is not an independent backup.

Upstream references: Btrfs `btrfs-subvolume(8)` (snapshot sharing and non-recursive
snapshot scope), `btrfs-balance(8)` (allocation workspace and usage filters), and
`Reflink` (shared data with separate inode/extent metadata).
