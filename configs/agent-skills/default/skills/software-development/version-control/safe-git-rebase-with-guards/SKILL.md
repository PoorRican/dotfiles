---
name: safe-git-rebase-with-guards
description: "Perform a git rebase safely when the branch may have uncommitted WIP, poisoned rerere cache, or a concurrent actor. Use for any non-trivial rebase/linearization in a shared repo or git worktree where conflict markers, WIP loss, or baked-in corruption are risks."
---

# Safe git rebase with guards

Use when rebasing a branch that (a) has uncommitted WIP, (b) may have a poisoned rerere cache from prior aborted attempts, or (c) shares a repo/worktree with another session. Optimized to NEVER lose the user's work and NEVER bake conflict markers into history.

## 0. Pre-flight
- `git rev-parse HEAD` and tag it: `git tag -f pre-rebase-safety HEAD`.
- `git status --short` — if any tracked/untracked WIP, archive it OUT of git BEFORE anything: `git diff HEAD > /tmp/wip-<name>.patch` (captures staged+unstaged). Save each divergent variant separately. Stashes are repo-global and can be mutated by other worktrees/sessions — patches are the reliable backup.
- Detect a concurrent actor: `git reflog -10`. Any `commit`/`commit (amend)`/`rebase (abort)` you didn't issue = another process writes this branch. Probe stability: record HEAD + `git rev-parse refs/stash`, `sleep 8`, re-check. If anything moved, STOP and escalate — do not rebase into a moving target.

## 1. If linearizing an already-merged branch
- Check whether origin/master is already an ancestor: `git merge-base --is-ancestor origin/master HEAD` (exit 0) and `git rev-list --left-right --count origin/master...HEAD` (left side 0). If so the topological goal is already met; a rebase only changes cosmetic linearity and will re-resolve every conflict the prior merge already handled. Confirm the user wants that.

## 2. Start
- Clean the tree (stash the WIP; you already have the patch backup).
- `git -c rerere.enabled=true -c rerere.autoupdate=true rebase origin/master`.

## 3. Guarded continue loop (the core)
At every stop, in order:
1. Done? `test -d "$(git rev-parse --git-path rebase-merge)"` false -> complete.
2. **Full-tree marker scan** (NOT just --diff-filter=U): for each file in `git diff --name-only; git diff --cached --name-only; git ls-files -u|awk '{print $4}'`, grep `^(<<<<<<<|=======|>>>>>>>)`. If ANY marker file -> STOP the auto-loop and resolve it by hand (see 4). rerere can de-register a file from ls-files -u while leaving markers unstaged; a U-only guard misses it.
3. Stage ONLY specific marker-free conflicted paths: `git add <path>` — NEVER `git add -A` / `git add -- $M`.
4. `PREV=$(git rev-parse HEAD)`; `GIT_EDITOR=true git -c rerere.enabled=true -c rerere.autoupdate=true rebase --continue`; `NEW=$(git rev-parse HEAD)`.
5. **Anti-bake-in**: for `c in $(git rev-list PREV..NEW)`, `git show $c | grep -qE '^\+(<<<<<<<|>>>>>>>|=======$)'` -> if hit, a marker was committed; abort and restart.

## 4. Resolving a stopped conflict
- Compare against the known-good target (e.g. the prior merged tip): `git show <merged-tip>:<path>`.
- If the current commit is the LAST replayed commit to touch that file (`git log --oneline <commit>..<merged-tip> --not origin/master -- <path>` empty), resolve = merged-tip content: `git checkout <merged-tip> -- <path>`.
- Otherwise resolve only the marker block faithfully (pick a side or combine both intents). In OMP, use `conflict://` writes (read+write one file back-to-back; ids churn across files). apply_patch/edit target the ROOT checkout, not a worktree — don't use them for worktree files.
- Intermediate commits need NOT compile; only the final tree + gate must be correct.

## 5. rerere poison recovery
- Symptom: markers reappear in a file across restarts (rerere replaying a bad recorded resolution from a prior blind add).
- Fix: `git rerere forget <path>` during the conflict, then resolve correctly; or `rm -rf "$(git rev-parse --git-path rr-cache)"` to wipe all (also loses good entries -> re-resolve all by hand).

## 6. Definitive end-state proof
- `git diff <pre-rebase-tip> HEAD` MUST be empty (proves the linearized result equals the reviewed pre-rebase content).
- `git rev-list --merges origin/master..HEAD` MUST be 0 (proves it actually linearized).
- No commit contains markers (step 5 scan over `origin/master..HEAD`).
- Then run the project gate (fmt/clippy/test).

## 7. Restore WIP (only after rebase)
- `git stash apply --index <ref>` or re-apply the archived patch; verify against `git stash show -p`. Drop only after verified.
