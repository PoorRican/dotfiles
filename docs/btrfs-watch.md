# Computebox Btrfs Watch

Independent, alert-only monitoring of filesystem UUID
`12019150-ad54-405b-b8e7-ffa3a112ed02` mounted at `/`. Source configuration is
`nix/modules/btrfs-watch.nix`, imported only by cbox. The Python monitor is
`bin/cbox-btrfs-watch.py`.

## Current deployment — October 23, 2026

The 08:00/20:00 schedule and compact notifications are deployed. Only the
watchdog service, timer and its existing enable link were updated; no full
Home Manager activation or unrelated desktop change was applied.

The current unit bundle is:

    /nix/store/1akw36mz0d35jcxmjd1nfxj3c6gcd5iq-cbox-btrfs-watch-deployment

It is GC-rooted at `~/.local/state/btrfs-watch/deployment`. The store script
matches the source byte-for-byte. All 60 source tests and Ruff passed, as did
all 56 CLI tests against the exact store script and pinned Python. The rendered
units passed `systemd-analyze --user verify`.

Readback confirmed an enabled, active calendar timer, no startup/five-minute
trigger, zero randomized delay and a next check at 20:00 MST on October 23.
A manual service verification completed at 13:31:16 MST with exit status 0,
published state and respected the existing notification cooldown. A print-only
preview exercised the compact body without changing live state. No new desktop
alert was sent for this verification, and a complete 12-hour automatic cycle
has not yet been observed.

## Original deployment history — October 9, 2026

Selective live deployment was verified on October 9, 2026. Only
`cbox-btrfs-watch.service` and `cbox-btrfs-watch.timer` were installed; no full
Home Manager activation was performed. The timer is enabled, with successful
automatic samples at 23:26:29 and 23:31:32 MST (303.19 seconds apart). The
second sample retained the warning-notification cooldown rather than repeating
it. State directory/file permissions were verified as 0700/0600.

The original reviewed unit bundle was:

    /nix/store/wkwj65g9h2bf1il8dq3p15maj1yjc7n0-cbox-btrfs-watch-deployment

At that deployment the GC root was `~/.local/state/btrfs-watch/deployment`; its store
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

Twice daily at **08:00 and 20:00 host-local time** (MST on cbox), with no
randomized delay and up to 10 seconds of timer coalescing. There is no startup
or missed-run catch-up check; a stopped host waits for the next scheduled time.
The pressure thresholds are unchanged:

| Signal | Warning | Critical |
| --- | --- | --- |
| Logical metadata occupancy | >=85% | >=95% |
| Metadata margin after accounted reservations | <=20 GiB | <=5 GiB |
| Raw device-unallocated space | <=50 GiB | <=10 GiB |
| Recorded device errors or read-only mount | — | Any |

The existing growth detector requires samples 45–75 minutes apart and warns at
>=1 GiB/hour. **Normal 12-hour sampling cannot provide that window, so hourly
growth alerts are unavailable at this cadence.** Manual samples can still
provide it; the detector never invents an hourly rate from 12-hour history.
These are deliberately conservative local policy thresholds, not Btrfs
universal failure boundaries. The reservation-adjusted margin is a pressure
indicator, not a guarantee of writable capacity. Samples are live, non-atomic.
Growth alerts require sufficient real history; first-run output cannot establish
a rate. Missing or failed queries fail visibly rather than assuming health.

State is bounded to seven days and at most 2,016 measurement points. Notifications
normally contain just metadata occupancy, reservation-adjusted margin and raw
device-unallocated GiB, with a short extra line for growth, a read-only mount or
recorded device errors when applicable. Failure alerts are also concise; full
measurements, reasons, caveats and failure diagnostics remain in state/journal
output. Warning/critical cooldowns remain six hours/one hour for manual runs,
with immediate escalation on a sample; automatic checks can alert only at the
two scheduled times. A failed notification must not advance its cooldown.
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
