# Worktree retirement and loss audit

Scope: Read-only audit of what could be lost before branches, worktrees, snapshots or scratch directories are deleted, plus the removal and preservation steps once deletion is approved.

## What the audit answers

- "Every branch is an ancestor of the target" proves ancestry, not content: `-s ours` merges and lineage-variant conflict resolutions keep a branch's history while dropping its files. Answer with three lists: branch content the target lacks and why, work never committed to any ref, and what is kept out by design. Run everything read-only; committing or moving anything needs the owner's approval. (src: master-exclusion-audit, 2026-11-08)
- A read-only scout may have no shell, git or cluster access. Give it a precomputed inventory file and verify every "merged" or "mine" claim with git yourself before reporting.

## Branch content, per path

Script it over `git ls-tree -r -z`, `git diff --name-only -z <merge-base> <branch>` and `git cat-file -p`, caching blob text.

- The mainline is the branch the target was built from. After a merge every branch blob is reachable from the target through the merge parents, so reachability proves nothing: compare against the pre-merge mainline's objects (`git rev-list --objects <mainline>`) and against the target's tree. For a plain PR history use `git branch [-r] --no-merged origin/<target>` and the objects of `origin/<target>`; a branch file whose tip blob appears anywhere in the target's history is an older (superseded) version, not an excluded one.
- For each local branch `b` whose tip differs from `mb = git merge-base <mainline> b`, classify every path it changed:
  - identical: the target's blob equals the tip blob;
  - older version: the tip blob is among the mainline's objects; it was committed there and the file moved on;
  - deletion not applied: the tip lacks the path and the target has it;
  - content present: every non-blank line the branch added occurs in the target's file (an order-blind set test, for triage only);
  - excluded: file not in the target, target kept the mainline version (target = mainline != `mb`), branch change not applied (target = `mb`), or only partially present.
- Report only the excluded classes, deduplicated by (path, blob), with a sample of absent lines.
- Before calling lines lost, check whether a later commit on the same lineage rewrote them (present in `<c>^`, absent in `<c>`); for docs, scan the versions listed by `git rev-list <mb>..<target> -- <path>`.
- Read the merge commit messages, which should explain each lineage-variant choice.
- Map branches to PRs once (`gh pr list --state all --json number,headRefName,state,mergedAt,headRefOid` with a high `--limit`). A closed PR's `refs/pull/<n>/head` survives branch deletion, so only PR-less, local-only refs can lose content.

## Work never committed anywhere

Build `any = git rev-list --objects --all` (and the same for `--branches` separately). Hash candidate files with `git hash-object --no-filters --stdin-paths` run from the repository, and report hashes absent from `any`. Where to look:

- Gitignored code directories: `git ls-files --others --ignored --exclude-standard -- <dir>` filtered to code, scripts and config. Launchers and records can live there.
- Gitignored nested `.worktrees/` folders inside checkouts and worktrees. Worktree tooling can copy ignored directories into new worktrees, leaving stale and sometimes self-nested copies that can be many gigabytes; walk each copy at depth 1 and skip the recursive child. A copy can hold the only source of a tool.
- Frozen snapshot trees, walking text files and skipping virtualenvs, `.git`, caches, `*.egg-info` and symlinks.
- Orphaned or restored worktree copies: a directory whose `.git` file points at a missing admin directory is invisible to `git worktree list`, and git inside it fails with `fatal: not a git repository: (null)`. Treat it as a plain tree and hash its files against `any`.
- Every stash, via `git log -g refs/stash` (not just `stash@{0}`), including `^3` for untracked files. `preserve/*` branches often hold real unlanded fixes; read them instead of calling them archives.
- Refs created by another VCS front-end (`git for-each-ref refs/jj`): list blobs reachable only from each with `git rev-list --objects <ref> --not --branches | git cat-file --batch-check='%(objecttype) %(rest)'`. Empty-subject commits are working-copy snapshots; diff them against the matching snapshot branch.
- Registered worktrees: `git worktree list --porcelain`, then `git status --porcelain=v1 --untracked-files=all` in each. `git diff --summary` with `--numstat` separates mode-only changes from content changes. Hash edited files too, because that version may already be committed elsewhere. For a detached HEAD run `git merge-base --is-ancestor <head> origin/<target>`.
- Running processes whose code lives only in an ignored or scratch path: tie them to paths through `/proc/<pid>/cwd` and the executable path.

## Bounded discovery and evidence selection

- For a large checkout forest, scan directory entries without following symlinks and persist both findings and the pending directory queue between bounded batches. A timeout or nonempty queue means incomplete coverage, not deletion clearance. Recover completed receipts before rescanning, separating historical counts, successful removals, instrument failures and holds. Inspect small materialized package sources and original vendored artifacts where ordinary source has disappeared.
- For a bounded disk census, GNU `du -x --block-size=1 --max-depth=1 --null` emits NUL-separated records. Capture stdout, stderr and exit status separately; permission errors, timeout or a missing parent row make coverage incomplete. For a stalled forest, use complementary non-overlapping child scopes and record filters and hard-link conventions. Bare `--time` reports modification time; `--time=ctime` reports status-change time. Do not sum overlapping parent and child totals or equate apparent namespace measurements with physical reclaim.
- Identify build-output candidates by shallow checkout-container scans, recording unscanned edges rather than recursively traversing dependencies. Separate build-output categories and treat a configured target directory as a lead: environment, other configuration and command-line overrides can change it. Do not run a build merely to find candidates.
- Label the primary HEAD, cached default ref and freshly queried authoritative default SHA separately: a query is not a fetch. Recheck the inventory's head map and paginate remote PR listings. Tree and path-blob equality can establish content identity despite divergent ancestry or patch IDs; dirty working bytes are a separate comparison. An unavailable remote association is unknown, not proof of unmerged work.
- Distinguish an owner's delegated value-based disposal decision from an audit-only or exact-preservation mandate; obey applicable age and activity restrictions. Examine positive, null and contrary results, amendments, provenance, producing code and the minimum restart inputs before selecting outputs. A result or artifact URI alone does not prove the referenced bytes survive.
- Classify original paths and aliases for privacy before opening, hashing, extracting or invoking Git operations that read their bodies. File extensions and content-addressed member names do not override a metadata-only restriction. Exclude a restricted member globally across aliases; label cached proofs as cached, not fresh readback. Stop and issue a scoped correction if prohibited reads occurred. A versioned example is not automatically safe by name: require evidence of its template role, tracking and retained history; hold credentials and unresolved sensitive sources.

## Preserving selected evidence

- Use the approved preservation review to define exact roots, protected live roots, selected receipts and omissions. Write a selection plan before copying, accounting separately for source bytes and unique retained bytes and recording authorized per-file exceptions. Bounded payload inspection does not replace complete worktree discovery. Preserve separate staged and working patches and list ignored or configuration namespaces omitted from a rescue.
- For each selected source and alias, record its producing root and revision, archive member, size and digest; identify inherited provenance as historical. Stream payloads, avoid following symlinks, and compare source identity and metadata before and after reading. Do not overwrite a completed archive. Independently verify the exact permitted member set, sizes and SHA-256 bytes and read compressed streams to EOF; an archive checksum or another person's report alone is not member readback. Verify declared input counts and receipt hashes where applicable.
- A selected-member rescue is not a whole-root backup, full recomputability, off-host protection or deletion clearance. Report preserved, discarded and unknown classes, member and source counts, retained bytes, exceptions, held roots and verification gaps. Preserve required original release artifact bytes and provenance outside expiring scratch; a rebuild with the same version does not prove byte identity.
- Before running a frozen packet's validator, inspect imports, top-level effects and output destinations; avoid writing into the original packet. Use fresh output locations and the actual intended interface rather than importing a producer that mutates its input.
- Recovery refs require separate authorization and protect reachability, not disk failure or deliberate deletion. For an archived patch, a private alternate index can load the recorded base, check and apply the patch, and a second alternate index can reverse it to prove the original tree; compare the changed pathset with the full archived pathset. Preserve staged intent separately. Restore untracked files only from a reviewed packet whose paths, types, modes, sizes and permitted bytes are verified. Create recovery refs create-only, read them back, and compare primary HEAD, real index, status and dirty bytes before and after.
- Retained live-file witnesses are mutable dependencies: before a later deletion, identify witnesses under its proposed scope and requalify them or hold the scope. Replacements need independently verified archive members or Git blobs with surviving refs. Git preserves file bytes and executable semantics, not arbitrary ownership, timestamps, ACLs, xattrs or other mode bits; record reconstruction requirements.

## Authorized bounded removal

- Authorization to investigate or preserve is not authorization to delete, push, start workers or alter retention. Freeze exact approved targets and exceptions. Classify audit reports by purpose, not extension; explain any loss of historical replay and preserve recovery inputs unless separately authorized.
- Inspect visible process cwd, executables, open files, mappings and mount boundaries before removal; a point-in-time survey is not a lease against future writers. An editor mapping a build artifact is evidence of editor use, not necessarily a running build; disclose invalidation and hold unresolved cases. Keep active targets on hold and re-evaluate ignored outputs before revisiting them.
- For bounded removals, retain the exact approved manifest and checkpoints, and distinguish initially absent, completed, held and failed targets. A failed recursive removal may already have removed children: retain the native status, inspect exact remaining paths and any still-running worker, and never repeat completed removals. Match dispatched targets to the approved manifest; a background handle alone does not prove work began.
- `timeout --kill-after` can send KILL, and `timeout --verbose` reports signals it sends; exit 137 alone does not prove an out-of-memory kill or a timeout. Require matching diagnostics and postchecks before classifying a partial slice. A capped census remains incomplete.
- If permissions block approved removal, inspect ownership, object type, device and symlink or mount boundaries. Only adjust owner-write on exact owned directories after fresh identity and activity checks, without following links or changing regular files; foreign ownership, immutable flags and privilege denials require the supported authorization path. Privileged observations need independently authenticated scope and identity; never bypass a refusal or collect passwords in chat.
- Verify exact target absence, retained exceptions and recovery roots, registrations, refs and primary checkout status separately. Report partial cohorts and stale registrations; measure filesystem availability before and after rather than estimating reclaimed physical space from directory sizes.

## Removing worktrees in a repository others use

"Remove all worktrees" means remove every stale one and report the live ones. None of these proves abandonment: clean, pushed, no process with its cwd inside, quiet for 15 minutes; agent tool calls run in short-lived shells, so a live session usually has no process in its checkout between calls. (src: multi-agent-worktree-cleanup, 2026-11-08)

- Inventory with `git worktree list --porcelain` (path, HEAD, branch or detached, `locked`) and write a durable manifest (path, HEAD, branch, dirty count) outside any scratch directory you will delete. `git worktree remove` deletes the admin directory and the HEAD reflog, so a detached HEAD is recoverable only from your record. The main checkout may be on another actor's branch: never switch, reset or clean it.
- Probe with `git --no-optional-locks -C <wt> status --porcelain --untracked-files=normal`; a plain `git status` may refresh and rewrite that worktree's index, colliding with its owner and bumping the timestamps you use as evidence.
- Data-safe needs all of: empty status; HEAD on a remote ref (`git branch -r --contains <sha>`); nothing ahead of upstream; not locked; and no gitignored data that exists nowhere else. `git worktree remove` deletes ignored files even without `--force`, and porcelain status never shows them (observed 2026-11-02: two removed worktrees lost ignored output and cache directories that had been copied out first). List them with `status --porcelain --ignored=matching`, compare with `rsync -a --dry-run --ignore-existing --out-format=%n <wt>/<dir>/ <main>/<dir>/`, and copy unique data out first (`cp -a --reflink=always` costs no space on a copy-on-write filesystem) or keep the tree. A worktree that is the only home of its data should be locked: `git worktree lock --reason "<what lives here>"`.
- Live (any one means leave it unless the owner explicitly says to remove it): absent from your first inventory; HEAD or dirty state changed between two observations (a worktree went from 2 dirty files to a new commit mid-cleanup, 2026-10-25); recent writes in the tree or a recent mtime on `<repo>/.git/worktrees/<name>` (it moves with index and HEAD writes); tied to live runtime state; a process cwd inside it (`readlink /proc/<pid>/cwd`; absence proves nothing). Re-classify immediately before each removal.
- Remove with `git worktree remove <path>`, adding `--force` only after the data-safe checks pass. Never `--force --force`: it overrides a lock.
- A stale but dirty worktree gets its WIP committed, in that worktree only, to a local unpushed `preserve/<topic>-wip-<YYYYMMDD>` branch before removal; never do this in a live or shared checkout. Finish with `git worktree prune -v`, and delete a gitignored nested `.worktrees/` folder only after every registered tree inside it is gone.
- Recover with `git worktree add --detach <path> <sha>` or `git worktree add <path> <branch>`. Report the number removed, the manifest path, and each kept worktree with its liveness evidence. A tree whose HEAD had moved since an earlier check was removed anyway once (2026-10-25); nothing was lost only because it was clean and pushed, but the checkout vanished under its session.

## Preserving before deleting

- Approved push-before-delete: pin the branch and full commit OID, inspect the origin and any pre-push hook, push without force, and read back the exact remote OID with `git ls-remote`. A branch push preserves committed history only, not working files or ignored artifacts. Exact tip equality or ancestry to an actual remote head (not a cached remote-tracking ref) already shows the history is remote. (src: worktree-retirement-review, 2026-11-08)
- pre-commit's new-ref pre-push path returns without running suites when `git rev-list <oid> --topo-order --reverse --not --remotes=origin` is empty. Recheck that before pushing, verify the remote ref, and never describe the early return as passing tests. A per-command hook exception needs explicit approval for that exact purpose.
- Originless task repositories: `git remote` listing no `origin` is not zero remotes; check exact commit containment in known canonical repositories before inventing a destination. For a local-only backup use a private `git bundle`, restore every advertised tip into an owned test repository, run a strict `git fsck`, and report it as a local backup, not an upload. Deduplicate tips by repository and commit: the same HEADs can have different working changes, ignored outputs and VCS-front-end state.
- A gitlink (mode `160000`) commit can be unreachable from the archived outer HEAD; archive it separately. Inspect index modes before describing a checkout as clean.

## Landing recovered work (after the owner approves)

Ask where it goes first: the existing PR branch, a local commit only, or nowhere. (src: master-exclusion-audit, 2026-11-08)

1. Byte-compare every surviving copy (`diff -rq`, excluding caches and virtualenvs) and compare the chosen copy with the target branch by blob OID. Proceed only if it is "branch head plus N changed files" with nothing missing; a copy on another base needs a rebase plan, not a copy.
2. The branch must not be checked out elsewhere, and local, remote and PR heads must agree (`gh pr view <n> --json headRefOid`). Add a fresh worktree, copy only the identified files, and check `git diff --summary` for mode changes.
3. Run the branch's own CI steps from its workflow files, not a guessed subset.
4. Commit the recovered tree first, then any local-only patch, so the tip equals what runs. Stage explicit paths and leave out credentials and agent scratch. Say in the message what the recovered tree still lacks.
5. Verify before pushing: for every file `git rev-parse <commit>:<path>` equals `git hash-object --no-filters <source file>`, and the tests pass on the tip.
6. Push as a fast-forward; `gh pr view` can show the old head for a few seconds afterwards, so re-check before reporting. Remove the temporary worktree.

## Report

Lead with the verdict, then list excluded branch items and their reason (lineage variant, `-s ours`, superseded), never-committed work (flagging files a running process or installed tool executes and files whose hashes a record binds), and what is kept out by design (`.gitignore`, mode-only changes). Offer commits or protection, and perform them only after approval.
