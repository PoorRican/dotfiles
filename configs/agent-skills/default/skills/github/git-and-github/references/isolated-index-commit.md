# Isolated index commit

Use an alternate index when committing owned changes would otherwise include another writer's staged paths or shared-file hunks. Coordinate writers: index isolation alone does not lock the branch ref or working file.

1. Record the expected branch, HEAD and real index entries. Construct each mixed-file blob from HEAD plus only owned edits, preserving file mode; compare it with the working file to account for foreign changes. Do not stage the entire shared file.
2. Set `GIT_INDEX_FILE` for every command in an isolated environment, initialize it from the recorded HEAD with `git read-tree`, install the intended blobs with `git update-index --cacheinfo`, and use `git write-tree`. An existing empty file is not a valid index.
3. If hooks are required, use an appropriate real hooked commit workflow instead of `git commit-tree`, which bypasses hooks. Otherwise create a commit from the tree and recorded parent and advance the branch with `git update-ref <ref> <new> <old>`; the expected-old value prevents overwriting a concurrent commit.
4. Realign only real-index paths proven free of foreign staging, then inspect the committed tree, remaining staged entries and working diff. A failure after the ref update may mean the commit already landed; inspect history before retrying.

Use unique content anchors rather than mutable line numbers when constructing a blob. Duplicate lines, modifications and deletions make line-set comparisons insufficient: inspect and verify the intended regions and residual diff. An index lock does not protect against a concurrent branch-ref advance.

The following plumbing bypasses commit hooks. Use it only when the repository does not require a hooked commit; otherwise use a real hooked commit workflow. For a tracked path with its real-index entry equal to HEAD, after constructing and verifying the owned-only blob:

```bash
set -euo pipefail
OLD=$(git rev-parse HEAD)
# MODE comes from git ls-files -s -- "$P"; BLOB is the verified owned-only blob.
GIT_INDEX_FILE="$IDX" git read-tree "$OLD"
GIT_INDEX_FILE="$IDX" git update-index --cacheinfo "$MODE,$BLOB,$P"
TREE=$(GIT_INDEX_FILE="$IDX" git write-tree)
test "$TREE" != "$(git rev-parse "$OLD^{tree}")"
NEW=$(git commit-tree "$TREE" -p "$OLD" -m "$MSG")
git update-ref "refs/heads/$BRANCH" "$NEW" "$OLD"
git reset -q -- "$P"
```

Use a private nonexistent index path, verify branch and index entry before starting, and coordinate writers across the operation. The last command is appropriate only for a path proven free of foreign staged changes; preserve and compare other staged entries. For several paths, update each in one index and reset only those proven safe. If compare-and-swap fails, rebuild against the new HEAD; never force it. `commit-tree` bypasses hooks, so run required checks separately or use the required hooked workflow.
