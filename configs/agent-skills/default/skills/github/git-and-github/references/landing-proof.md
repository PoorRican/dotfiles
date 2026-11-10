# Landing proof

Scope: Authority for a merge request, proof that a merge landed exactly what was tested, and the mechanics of landing PR batches and chains of local branches.

## Authority and scope of a merge request

- "Merge all of this" authorizes merging, not deploying: applies to a running system, secret projections, rollouts and image deploys still need explicit approval. A closeout request authorizes merging and recording, not launching jobs or building data, even when the closeout recommends it. Opening a PR does not authorize merging it. Report merged and live separately, list the steps that still need approval, and flag steps that must be applied together. (src: cross-repo-pr-landing, 2026-11-08; research-line-closeout, 2026-11-03)
- "All of this" means the current workstream. List its open PRs, check each is ready (`gh pr view <n> --json state,mergeStateStatus,mergeable,isDraft,headRefOid,statusCheckRollup`), merge the ready ones, and only then report ambiguous local branches. A long branch survey before merging drew an owner interruption (2026-11-03). Do not sweep in months-old PRs from an author search: agent PRs show the owner as author, so authorship does not identify the session. Merge providers before consumers. A narrow PR carved off a broad local branch merges alone; leave the broad branch, especially WIP commits, to its owner and report it.
- Find unpushed work that never became a PR: `git log origin/<base>..<branch>` (a shared checkout also holds other sessions' commits; only your own are in scope) and `git ls-remote --heads origin <branch>` for local-only branches. A repository with no remote has nothing to land: a commit on its branch is already landed.
- Re-derive the merge style from the repository each time (`git log --first-parent --merges -n 10 origin/<base>`); recorded conventions go stale (a table row that said rebase-merge was found out of date on 2026-11-08).
- For an unpublished intended base, pin local base and topic SHAs and inspect the extra history and topic diff before seeking authority to publish it. Pathname and large-file inventories are not secret-content audits. If approved and the remote supports atomic pushes, `git push --atomic REMOTE BASE_SHA:refs/heads/BASE HEAD_SHA:refs/heads/TOPIC` publishes the pinned refs together; read back both SHAs and do not force concurrently advanced refs. Check for an existing head/base PR before creating one with explicit repository, base, head and body; verify its returned fields and diff.
- Read the installed hook and affected workflow triggers, `needs` and publication conditions before estimating release time or crossing an automatic-write hold. Retain one completion-notifying process handle for a long push or workflow and inspect its result and the remote SHA before retrying. Approval denial means not run, not a failed hook; a command without an exit result is neither pass nor failure.
- For readiness inspect the exact head, base, job graph, review and thread state; qualify the workflow event and attempt. Distinguish trigger-gated skips from failure-induced skips, and do not call an empty check rollup successful. Required checks and branch protections still apply.

## Merge-commit landing proof

- Use a merge commit when an external record cites branch commits (artifact metadata recording a producer commit, a written note): GitHub's rebase and squash merges rewrite SHAs. Check `git merge-base --is-ancestor <cited> origin/<base>` before and after. (src: experiment-repo-branch-landing, 2026-11-01)
- In a repository with no CI, pin the tested head: `gh pr merge <n> --merge --match-head-commit <tested sha>`. Then prove the result: `origin/<base>^1` is the old base, `^2` is the tested head, and `git rev-parse origin/<base>^{tree}` equals the head's tree (true when the head already contains the base tip). The pin protects the PR head, not the base: concurrent PRs can change the merged tree (see [pr-stacks-merges-and-reviews.md](pr-stacks-merges-and-reviews.md)).
- State PR-body claims at the scope they had. "Each merge tree equals the tested tree" needs gate output per PR or a note that it was not kept (a reviewer flagged a blanket claim, 2026-11-03). A PR body shaped `## Summary` / `## Verification` / `## Not included` keeps claims and gaps separate.
- A workflow that never runs for pull requests (publish-on-push to the base) validates nothing the branch introduces; name what publishes only after merge under "Not included", and report a failed post-merge precondition (for example a build-capacity check) instead of promising publication. (src: cross-repo-pr-landing, 2026-11-01)

## Gating a repository with no CI

The author's local gates are the only evidence, so make the tested tree and the merged tree the same tree.

- Merge without rerunning only if the head's parent is the current `origin/<base>`. Otherwise `T=$(git merge-tree --write-tree origin/<base> <head>)`, wrap it with `git commit-tree "$T" -p origin/<base> -p <head> -m scratch`, add it as a detached worktree, copy in ignored inputs the build needs, sync dependencies frozen, and run the formatters, type checker and tests there (memory-capped on a shared host).
- After the pinned merge confirm `git rev-parse <merge>^{tree}` equals `T`. When the base moves, recompute `T` for the next PR.
- At authorized landing re-read both head and base. Qualify the exact head/base pair; a merge-tree preview is content evidence, not a test run. If the base moved, re-establish qualification for the changed pair; read back the merged PR and exact merge commit. Head ancestry is evidence only for history-preserving merges.
- Merge the current base into the branch first; never rebase published or artifact-referenced commits. Resolve add/add conflicts as unions where both sides add, then gate the merged head.
- When the base moves after the gate, do not re-gate by default. Re-merge, prove `git diff --raw <gated-tip> <new-tip>` lists only paths the base's new commits changed and that the branch's paths keep identical blobs, `git grep` the changed paths under the tests, and land. Re-gate only if the base's new commits touch code or tests. An owner who commits directly makes a moving base normal.

## Stacks, dependents and your commits among others'

- Merge stacked bases first, then open or retarget the next PR so its diff holds only its own commits.
- Landing your own unpushed commits when the main checkout also holds other sessions' commits and edits: add a worktree off `origin/<base>`, `git cherry-pick -x` each commit in order (stop on conflict), read any auto-merged section to confirm your text landed in the right place, check that `git diff --stat origin/<base>..HEAD` shows only your files, open the PR and merge it. Leave the main checkout untouched; a later rebase there drops the duplicates.
- Landing another session's uncommitted worktree: read its authoring session's final report (intent, verification done, what is still open), check that no process has its cwd in the tree, commit explicit paths with subject-only Conventional Commits, and run an independent reviewer for blocking defects in parallel with the gate. Whole-project commit hooks also check untracked files, so a broken untracked script fails every commit (see [commit-splitting-and-hooks.md](commit-splitting-and-hooks.md)). (src: experiment-repo-branch-landing, 2026-11-02)

## Bringing a stale branch to a PR

- Triage read-only: `git fetch origin`, `git merge-tree --write-tree --name-only --messages origin/<base> HEAD`, then read both sides of each overlapping path (`git diff $(git merge-base HEAD origin/<base>) <side> -- <path>`). Where history uses merge commits, merge instead of rebasing: `git merge --no-ff --no-edit origin/<base>`.
- Never hand-merge generated files (lockfiles, tag manifests, rendered schemas): regenerate from the merged tree with the repository's generator, then run its check. On a merge commit pre-commit checks only conflicted files and path-triggered hooks fire only on their input files, so nothing regenerates for you.
- Textual merges of workflow YAML can put a step in the wrong job: compare `yaml.safe_load` of the base, branch and merged versions per job.
- A worktree's copied virtualenv can keep entry-point shebangs that point at the original checkout's interpreter; use a private environment or `python -m` so the worktree's own code is tested. (src: cross-repo-pr-landing, 2026-11-01)

## Publication evidence

- Keep branch publication, annotated-tag object and peeled commit, package or image publication, default-branch integration and runtime activation separate. `git ls-remote REMOTE refs/heads/BRANCH refs/tags/TAG 'refs/tags/TAG^{}'` distinguishes the branch, tag object and peeled commit; a tag alone proves neither branch publication nor integration.
- For a published package fix, choose a new version and tag; verify both are free without treating authentication or transport failures as absence, and prove the old tag and artifact checksum unchanged. Publishing or installing a new version does not update pinned consumers.
- Qualify a package from its built wheel in an isolated environment: verify import location, distribution and runtime versions, declared dependency modes and interpreter matrix. Pin the release commit, publish the annotated tag through normal hooks, read back its object and peeled commit, and identify the exact release run by source SHA, tag event and attempt. Inspect the upload step; download that run's artifact and the index artifact using approved trust settings, compare hashes and packaged source, and report consumer adoption separately. (not re-run)
- For an image, identify the push-step digest for the exact source commit and permitted event, then independently inspect the registry manifest and source revision label. Compare index with index or platform manifest with platform manifest, not a configuration ID. When payload inspection is authorized, inspect the immutable image in a no-network, read-only container without checkout mounts or import-path overrides; compare the shipped module hash with qualified source. (not re-run)


## Chains of local branches

For a finished campaign whose trunk and per-lineage branches land locally. (src: experiment-lineage-branch-landing, 2026-10-04)

- Candidates are branches for which `git merge-base --is-ancestor <branch> <base>` fails. Leave unrelated unmerged branches alone and name them in the report. Check whether cross-repo work already landed through a PR (`gh pr list --head <branch> --state all --json number,state,mergedAt,headRefOid`, comparing `headRefOid` with the local tip). Use pairwise `--is-ancestor` to find each lineage's tip.
- Map overlaps before merging: `git diff --name-status "$(git merge-base <base> <b>)" <b>` per branch, and `git rev-parse <tip>:<path>` across tips for paths several branches touch. Identical blobs merge cleanly; lineage-variant paths (each branch adds its own content) add/add-conflict, so choose the winner first (the lineage closest to the base with the latest fixes). During the merge only pick a side; never edit content that produced receipts. Simulate each merge with `git merge-tree --write-tree --name-only --messages <base> <b>` (exit 1 means conflicts).
- Build the chain in a detached worktree off the recorded old base (`git worktree add --detach "$W" "$OLD"`): clean branches first, then each lineage's tip, then variant and record-only merges. Always pass `-m "Merge branch '<b>'"` (a detached `--no-edit` writes "into HEAD"), matching the style shown by `git log --first-parent --merges` (`git show --remerge-diff <merge>` shows how earlier conflicts were resolved). Never `--no-verify`: hooks run on merge commits.

```bash
git merge -q --no-ff --no-commit "$L" || true
test "$(git diff --name-only --diff-filter=U | sort | tr '\n' ' ')" = "<expected variant paths, sorted, space-terminated> "
git checkout --ours -- <variant paths> && git add -- <variant paths>
for p in <variant paths>; do test "$(git rev-parse ":$p")" = "$(git rev-parse "<winner>:$p")"; done
if grep -n -E '^(<<<<<<<|=======|>>>>>>>)( |$)' <variant paths>; then echo "conflict markers"; exit 1; fi
git commit -q -F <message file>
```

- Scan for conflict markers explicitly: `rerere` can drop a path from the unmerged list. Under `set -e` never guard with `! cmd` (bash exempts `!` pipelines from errexit); use `if ...; then exit 1; fi`. Write message files before any step that can abort. Name the variant paths, the kept winner and where the dropped variants live in the merge message. To keep the base's version of a path through a merge, `git restore --source=HEAD --staged --worktree -- <paths>` (`git add -f` if the path is ignored).
- Prove the merged tree: expected tree = old base tree plus each branch's merge-base-to-tip changes (deletions popped), computed over `git ls-tree -r -z`. Assert that every differing path has an owning branch, single-owner paths equal the tip blob, shared paths agree except variants, protected paths are byte-identical to the base, the final tree equals the expected tree, and every branch tip is an ancestor of the result. If the package tree of the result differs from a lineage tip's, record that reproductions must check out the lineage branch.
- Lint only what the merge changed (`git diff --name-only "$OLD" HEAD`). Fix lint and format on the source branch, discard the scratch chain (remove and re-add the detached worktree at `OLD`) and rebuild; the conflicts recur identically and the rebuild is quick. Do not edit the merge itself.

## Landing locally without touching foreign edits

- On the expected branch at `OLD`; no `MERGE_HEAD`, `REBASE_HEAD`, `CHERRY_PICK_HEAD` or rebase directories; nothing staged; dirty paths disjoint from the changed paths; added paths absent from the checkout; then `git merge --ff-only "$T"` and an identical `git status --porcelain=v1` afterwards. The script and the overlapping-path variant are in [dirty-checkout-update.md](dirty-checkout-update.md).
- Never `update-ref` a branch that is checked out in any worktree (`git worktree list --porcelain`); use `merge --ff-only` there. If the base moved after the gate, the ancestor check fails before anything changes.
- Remove only the merge worktree (`--force` only when its HEAD equals the base and only ignored build artifacts remain) and scratch trees. Merge only on explicit instruction, keep branches and worktrees, and say whether the base was pushed.

## Cleanup and report

- Delete a merged branch (remote and local) only if no worktree has it checked out and it is already in the base: `git merge-base --is-ancestor <branch> origin/<base>` for merge commits; `git cherry origin/<base> <branch>` showing only `-` lines for rebase merges. Leave other sessions' branches and worktrees alone even after their PR merges, remove your own worktrees only when `git status --porcelain` is empty, and delete scratch files tied to a merged change only if verifiably obsolete.
- When a PR is described as already applied to a running system, prove live equals merged: a read-only diff of the rendered merged state against the live state (exit 0 means no drift). Secret projections cannot be diffed this way; cite the PR's applied evidence.
- Report a table of repository, PR, merge commit, base CI result and published digests, then merged versus live, then downstream consequences: consumers that now require data not yet published, open branches that must reconcile with the merged edits, and main checkouts left untouched.
