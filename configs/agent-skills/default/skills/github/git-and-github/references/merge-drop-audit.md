# Merge drop audit

Scope: Detecting default-branch content that a conflict-resolved or delegated merge silently dropped, deciding which lineage was newer, and repairing with per-file 3-way merges. Read-only audit; the repair opens a PR, so merging it needs the owner's authorization for that repository.

A merge can compile, pass tests and still delete work, typically when add/add or content conflicts were resolved by keeping one side wholesale. Audit every merge you did not resolve line by line yourself and every merge a subagent reports as "kept the X side". Whole-file side picks are covered in [branch-history-and-landing.md](branch-history-and-landing.md); proof that a landed tree equals the tested tree is in [landing-proof.md](landing-proof.md); this page measures what a resolution lost.

## Find the merges that resolved conflicts
- The final PR merge into the default branch is often conflict-free. Conflicts were usually resolved earlier, in an internal "bring the default branch into the PR branch" merge. Audit every merge in `git rev-list --merges <default-before>..<pr-tip>`, not just the last one.

## Measure dropped default-branch additions
For each two-parent merge whose one parent (`main_side`) is an ancestor of `<default-before>`:
1. `base = git merge-base main_side pr_side`.
2. Take the files changed on both sides since `base`.
3. List the lines `main_side` added since `base`: non-blank `+` lines of `git diff -U0 base main_side -- <file>`.
4. Report each such line that is absent, as an exact line, from the file in the merge result. A nonzero count means default-branch content is gone.

Save as `merge_drop_audit.py`; run `python3 merge_drop_audit.py <repo> <default-before> <pr-tip> [<result-ref>]`. Without `<result-ref>` each merge's own file contents are checked; pass the new default tip to check that the lines survive after a repair.

```python
import subprocess, sys

def git(r, *a):
    return subprocess.run(["git", "-C", r, *a], check=True, capture_output=True, text=True).stdout

def show(r, rev, p):
    x = subprocess.run(["git", "-C", r, "show", f"{rev}:{p}"], capture_output=True)
    return x.stdout.decode("utf-8", "replace") if x.returncode == 0 else None

def names(r, a, b):
    return {p for p in git(r, "diff", "--name-only", "-z", a, b).split("\0") if p}

repo, main_ref, tip = sys.argv[1:4]          # main_ref = default branch BEFORE the landing
result_ref = sys.argv[4] if len(sys.argv) > 4 else None
total = 0
for m in git(repo, "rev-list", "--merges", f"{main_ref}..{tip}").split():
    ps = git(repo, "rev-list", "--parents", "-n1", m).split()[1:]
    if len(ps) != 2:
        continue
    ms = [p for p in ps if subprocess.run(["git", "-C", repo, "merge-base", "--is-ancestor", p, main_ref]).returncode == 0]
    if not ms:
        continue
    main = ms[0]
    pr = ps[1] if ps[0] == main else ps[0]
    base = git(repo, "merge-base", main, pr).strip()
    for f in sorted(names(repo, base, main) & names(repo, base, pr)):
        res = set((show(repo, result_ref or m, f) or "").splitlines())
        added = [l[1:] for l in git(repo, "diff", "-U0", base, main, "--", f).splitlines()
                 if l.startswith("+") and not l.startswith("+++")]
        dropped = [l for l in added if l.strip() and l not in res]
        if dropped:
            total += len(dropped)
            print(m[:10], len(dropped), f, "|", dropped[0].strip()[:90])
print("missing lines:", total)
```

- Exercised on a disposable repository (2026-11-10): a wholesale `git checkout --ours` resolution of an internal merge printed the file with its dropped line count and `missing lines: 2`; a clean 3-way merge printed `missing lines: 0`.
- Limits: the check is by exact line, so a renamed file (it appears under one name per side) or reflowed lines can be missed or over-reported. Before calling a line a real loss, read the merged code around it: comments get folded and lines get reflowed. A substring grep can give a false negative.
- Re-running the audit without `<result-ref>` after a repair still flags the original merge, because it inspects that merge's own result. The repaired tip is checked with the fourth argument.

## Decide which lineage is newer by content, not date
- Take each fix commit on the side that was kept and check that all its added lines are present in the other side's version of the file. If they are, the other side is a content descendant (the fixes plus more work) and the resolution kept the older version.

## Repair with per-file 3-way merges in an isolated worktree
1. Branch from the current default tip in a new worktree; never use someone's working tree.
2. For each affected file run `git merge-file -L current -L older -L newer <file> <older-lineage version> <newer version>` (arguments are current, base, other; the file is rewritten in place). Extract the two versions with `git show <rev>:<path>`.
   - A file the default branch has not changed since the landing comes out identical to the newer version.
   - A file later PRs touched combines both sets of changes. The exit status is the number of conflicts (0 means clean): adjacent edits do conflict, so resolve the markers by hand and never take a side wholesale. Under `set -e` capture the status explicitly.
3. Commit only explicit paths. Some repositories track `__pycache__/*.pyc`; test runs rewrite them, so `git checkout --` those before committing.
4. Open a PR and merge it with a merge commit.

## Verify
- Compile and test the touched packages. Path-dependent sibling crates need detached sibling worktrees beside the fix worktree, and pre-push hooks need them too. Use a scratch build-output directory and delete it afterwards.
- Compare Python test counts before and after: deleted tests show up only as fewer collected tests. Install lazily imported dependencies before calling anything a failure.
- Re-run the audit with the new tip as `<result-ref>` and expect 0 missing lines; confirm changes merged after the landing survived.
- Confirm that pinned SHAs (image or CI pins) and the newer commit are still ancestors of the default branch.

## When delegating merges
The task must forbid wholesale side-picking on add/add conflicts, require 3-way content merges, require this audit's output in the report, and list each conflicted file with the side taken and the lines dropped.

Related skills: none.
