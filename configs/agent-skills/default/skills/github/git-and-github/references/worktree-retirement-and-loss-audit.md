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
