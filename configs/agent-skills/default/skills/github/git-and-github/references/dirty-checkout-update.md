# Dirty checkout update

Scope: Updating a checkout that has unstaged tracked edits (and possibly local commits or untracked files) to a fetched target while proving that nothing was lost.

## When it applies

- The index starts clean but tracked files carry unstaged changes, and the branch may have diverged from the fetched target. A dirty index needs separate handling: this procedure does not preserve staged intent. (src: verify-dirty-merge-preservation, 2026-11-08)
- Pre-existing local commits and modifications are foreign work until attributed. Preserve commits with a merge, not a reset or rebase, unless explicitly authorized otherwise. Do not manufacture a clean baseline by committing, stashing or resetting someone else's edits; checkpoint instead.
- Switching branches over foreign edits with `git switch -m` / `checkout -m` can print success and still leave unmerged entries (see [shared-checkouts-and-recovery.md](shared-checkouts-and-recovery.md)); take the checkpoint below first.

## Checkpoint before mutating

1. Identify the real repository root and expected branch. Record old HEAD `O`, fetch, and record the target commit. Decide about a fast-forward only after the fetch.
2. Snapshot the tracked changes without disturbing them: `W=$(git stash create "checkpoint: <topic>")` (empty output means no tracked change). Protect `W` with a unique ref such as `refs/backup/<topic>-<UTC timestamp>` so garbage collection cannot remove it.
3. Archive and fingerprint untracked files separately (`stash create` omits them) and record tracked deletions. Keep a binary patch and a manifest outside the checkout when recovery must be auditable.
4. Check that files and branch/HEAD did not move during the checkpoint. Bind the expected-branch and expected-HEAD check to the mutation itself; if another actor changed either, stop and reassess.

## Are the active changes already upstream?

A working file that differs from local HEAD is not necessarily new work. Compare against the prospective integration of the target with the existing local commits, not against the target alone.

1. `E=$(git merge-tree --write-tree "$O" "$TARGET")`; use `E` only when the command succeeds without conflicts.
2. Build the full working-tree snapshot in an alternate index outside the checkout. The variable must be exported for every Git command that uses it; a bare `GIT_INDEX_FILE=...` line is not exported, and the following commands would rewrite the real shared index. Keep it inside a subshell so it cannot leak:

   ```bash
   T=$(
     export GIT_INDEX_FILE="$SCRATCH_DIR/idx"; rm -f "$GIT_INDEX_FILE"
     git read-tree "$O"
     git add -- <initially dirty tracked paths and intended untracked paths>
     git write-tree
   )
   rm -f "$SCRATCH_DIR/idx"
   ```

   The tree includes tracked deletions and intended new files without touching the real index; confirm with a checksum of `$(git rev-parse --git-dir)/index` before and after (a worktree's index lives under its own git dir).
3. `T == E` means every active change is already covered by the target plus local history: there is no residual source change, and committing again would duplicate a logical commit. When they differ, inspect `git diff E T` for the residual work and do not discard it.

## Untracked files the target also adds

Identical untracked files that upstream adds still block a normal merge, and `--autostash` does not include untracked files.

- Re-check branch, HEAD, index and fingerprints, record the previous stash tip, then clear only the checkpointed paths with `git stash push --include-untracked --message <unique message> -- <explicit paths>`.
- Protect that complete stash under a unique backup ref; a ref to the stash commit keeps its parents, including the untracked `^3`, reachable.
- Merge the target without rewriting local commits. Verify the new HEAD tree equals `T`, that both `O` and the target are ancestors, and that the working tree is clean. Equality proves the original contents are now committed; never apply the stash, which would replay integrated changes.
- Only after that proof, drop the new stash if it is still the exact top stash and the earlier stash tip is restored. Keep the backup ref; never drop an unrelated or moved stash.

## Ordinary dirty merge and its proof

When the active changes are not wholly covered upstream and no untracked path obstructs checkout, `git merge --no-edit --autostash <target>` is a non-rewriting update. Do not use force, blanket ours/theirs resolution, reset or clean. On conflicts keep the checkpoint, resolve both sides deliberately, and do not claim restoration until the autostashed changes have actually been applied.

After a successful merge and restore, let `M` be the new HEAD:

1. Both `O` and the target are ancestors of `M`.
2. The expected tracked working tree is `git merge-tree --write-tree --merge-base="$O" "$M" "$W"` (use it only when it succeeds without conflicts). This is the original working changes three-way merged onto `M`; it avoids demanding byte-identical whole files that upstream legitimately changed.
3. Take another non-mutating `git stash create` snapshot `A` of the restored changes: `A^{tree}` must equal that expected tree. With no restored tracked change and no object returned, compare `M^{tree}`.
4. Verify untracked fingerprints, expected tracked deletions, a clean index and no unmerged entries separately. Run the checkout's real entry point and the repository's required checks, and report local ahead/behind, distinguishing a local merge from a push.

This comparison catches lost or altered working changes without treating upstream edits or shifted diff context as data loss. Keep checkpoints until it is safe to discard them; never delete unrelated branches, worktrees or stashes as cleanup.

## Fast-forwarding a dirty checkout

When the owner asks to bring a main checkout to a landed target and it has foreign edits, use one guarded script rather than a stash. (src: experiment-repo-branch-landing, 2026-11-02)

Preconditions; any mismatch stops the script before the checkout changes:

- HEAD is on the expected branch at the expected old commit and the target is the expected new tip (if another PR merged first, re-pin the tip and redo the precheck).
- No merge, rebase or cherry-pick is in progress (`git rev-parse --git-path MERGE_HEAD` and the rebase directories do not exist) and nothing is staged.
- No path added by the range (`git diff --name-only --diff-filter=A OLD NEW`) already exists locally.
- Dirty tracked paths are written to a file (`git status --porcelain=v1 --untracked-files=no | cut -c4- > dirty.txt`) and intersected with the range's changed paths using `grep -xF -f dirty.txt changed.txt`. Never use `grep -e "$var"`: an empty variable matches everything.

If the range does not touch the dirty files: back up `git status`, `git diff` and the untracked files' checksums (`git ls-files --others --exclude-standard -z | xargs -0 -r sha256sum`) outside the repository, run `git merge --ff-only NEW`, then assert HEAD, unchanged status, unchanged `git diff` and `sha256sum -c`.

If a dirty tracked file is also changed by the range, `--ff-only` refuses. Precheck outside the repository:

```bash
git show HEAD:F > base; git show "$NEW:F" > theirs; cp -p F local
git merge-file -p local base theirs > merged        # exit 0: no conflicts
strip() { grep -E '^[+-]' | grep -vE '^(\+\+\+|---) '; }
diff <(diff -U0 base local | strip) <(diff -U0 theirs merged | strip)   # empty: merged = theirs + exactly the local change
```

Compare changed-line sets as above; asserting that every added line is present with `grep -xF` gives false alarms on blank and repeated lines. Apply in one guarded script: back up `F`, its `git diff` and the untracked checksums, set an `ERR` trap that restores `F`, write `git show HEAD:F > F`, run `git merge --ff-only "$NEW"`, copy `merged` over `F`, then assert HEAD, `sha256sum -c`, and that the changed lines of `git diff -U0 -- F` equal the original local change. Run it only when no other actor is writing `F`, and report other processes that still hold the old files open: they keep the old modules until they restart.

## Staged work and qualified candidates

- Inventory staged and unstaged changes separately, along with untracked paths and parent/child collisions: a net `git diff HEAD` can hide offsetting changes. For a permitted fast-forward, preserve staged-diff fingerprints and affected working-file hashes and verify them afterwards; incoming entries can legitimately change the whole index hash. Exercise the actual index and worktree arrangement in a disposable fixture first. (method; actual hooks and worktree arrangement not re-run)
- For an authorized independently qualified descendant, coordinate writers and stop on drift. Require the primary HEAD to be the candidate's verified parent and the primary index to be empty. Retain exact backups, then apply only approved missing owned hunks to the working tree, preserving foreign edits; compare the result to both inputs. Apply the parent-to-candidate binary diff with `git apply --cached --check` and `git apply --cached`, require `git write-tree` to equal the candidate tree, recheck HEAD, and use ordinary `git merge --ff-only <candidate>`. Verify HEAD, index and working files separately. The generic transition was exercised in a disposable fixture; actual hooks and worktree arrangement were not re-run.
- If integration fails, retain the exact delta and report the state. Reverse only the owned cached delta after proving HEAD and index unchanged and excluding concurrent writers; never clear another actor's staging. For a dirty index, qualify the transition separately, recheck approved paths and exact backups, and stop if outside edits overlap the incoming delta. Protected-file approvals must precede writes. (method; not re-run)
- For documentary reconciliation, compare both committed parents and the working snapshot in an owned integration tree. Preserve unique evidence, qualifications and chronology, distinguish adjacent additions from substantive disputes, and check identifiers, links and claims against the inputs. Refresh HEAD, index and working hashes before adoption; a prepared candidate or synthetic fixture does not prove adoption. Report owned-path cleanliness separately from unrelated dirt and nested untracked worktrees. (method)
- For a NUL-delimited hash manifest, regenerate it over the same files in the same order and compare bytes with `cmp`; do not assume checksum check mode accepts zero-delimited output. Fingerprint only known non-secret files.
- An inactive branch may be fetched directly only when authorized and Git permits the update without force; independently prove the active checkout stayed unchanged. (method; not re-run)
