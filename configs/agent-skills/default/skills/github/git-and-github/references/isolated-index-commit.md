# Isolated index commit

Scope: Committing only your own lines or paths when the working copy also holds another actor's uncommitted edits, without writing the shared index or touching their edits.

## When it applies

- A file you edited also carries someone else's uncommitted change and you must commit only yours. With no foreign change in the file, a branch-guarded `git add <path> && git commit` is enough. Branch guards and ownership rules in [shared-checkouts-and-recovery.md](shared-checkouts-and-recovery.md) still apply. (src: shared-file-isolated-commit, 2026-11-08)
- First check that the record is not already committed (`git log -1 -- <path>`, `git diff --quiet HEAD -- <path>`): an owner's batch commit or a sync tool can sweep an uncommitted file in, and a session summary is not evidence of commit state. (src: isolated-line-commit, 2026-10-14)
- The same recipe builds the intermediate blob of a mixed file when splitting a tree into layers: HEAD plus only that layer's hunks, committed through a temporary index instead of interactive `add -p` staging. (src: split-stacked-changes, 2026-11-08)

## Why the usual commands are wrong

- `git add <path>` and `git commit -- <path>` take the whole working-copy file, foreign lines included.
- `git add -p` and `git apply --cached` write the shared index, which races other actors; a later `git commit` then sweeps in whatever they staged. `add -p` is also interactive and brittle for agents.
- `git stash` and checkout tricks rewrite the other actor's working-tree edits. A copy-aside variant (save the merged file, restore HEAD's version in place, re-insert only your line, commit, copy the merged file back) was used once, but it rewrites the shared file twice and stages through the shared index; another actor's write in that window is lost. Prefer the temporary index. (src: copy-aside lesson, 2026-09-21)

## Procedure

Work from the repository top level: pathspecs are cwd-relative, and `HEAD:<path>` needs a top-level-relative path. Run the block as its own `bash` process (a script on stdin), not inside a persistent shell where `set -e` would end the session, and keep the progress echoes: under `set -e` a failing `test` exits without printing anything. Keep `$SCRATCH_DIR` private to you.

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
P="dir/file.md"; BRANCH=main; MSG="docs: ..."
test "$(git rev-parse --abbrev-ref HEAD)" = "$BRANCH"
OLD=$(git rev-parse HEAD); echo "HEAD=$(git log -1 --format='%h %s' "$OLD")"   # read OLD in this block, never reuse an earlier status check
read -r MODE IDXBLOB _ < <(git ls-files -s -- "$P")     # take the mode from here; untracked path: this recipe is not needed
test "$IDXBLOB" = "$(git rev-parse "$OLD:$P")" && echo "index entry == HEAD blob"
BLOB=$(python3 - "$P" <<'EOF'
import subprocess, sys
p = sys.argv[1]
def git(*args, **kw):
    return subprocess.run(["git", *args], capture_output=True, check=True, **kw).stdout
head = git("show", f"HEAD:{p}").decode()
work = open(p, encoding="utf-8").read()
mine = [l for l in work.split("\n") if l.startswith("<unique prefix of your line>")]
assert len(mine) == 1, mine
lines = head.split("\n")
at = [i for i, l in enumerate(lines) if l.startswith("<prefix of the HEAD line yours follows>")]
assert len(at) == 1, at                      # the anchor must exist in HEAD, exactly once
lines.insert(at[0] + 1, mine[0])
new = "\n".join(lines)
known = set(new.split("\n"))
foreign = [l for l in work.split("\n") if l not in known]
assert len(foreign) == 1 and foreign[0].startswith("<prefix of their uncommitted line>"), foreign
assert sorted(work.split("\n")) == sorted(new.split("\n") + foreign)   # nothing dropped or invented
print(git("hash-object", "-w", "--stdin", input=new.encode()).decode().strip())
EOF
)
IDX="$SCRATCH_DIR/index.tmp"; rm -f "$IDX"              # git rejects an existing empty index file
GIT_INDEX_FILE="$IDX" git read-tree "$OLD"
GIT_INDEX_FILE="$IDX" git update-index --cacheinfo "$MODE,$BLOB,$P"
TREE=$(GIT_INDEX_FILE="$IDX" git write-tree); rm -f "$IDX"
test "$TREE" != "$(git rev-parse "$OLD^{tree}")"        # a rerun cannot create an empty commit
NEW=$(git commit-tree "$TREE" -p "$OLD" -m "$MSG")
git update-ref -m "commit: $MSG" "refs/heads/$BRANCH" "$NEW" "$OLD"   # compare-and-swap: refuses if the branch moved
git reset -q -- "$P"                                    # point only this path's real index entry at the new HEAD blob
git show --stat --format='%h %s' HEAD
git diff -U0 -- "$P"                                    # must show only the foreign edit
```

- Every step before `update-ref` writes only unreferenced objects. A failed assertion or a lost compare-and-swap changes nothing visible: re-read and rerun from the top against the new HEAD. Never fix a failed assertion by loosening it to let foreign lines through.
- Several files in one commit: one temporary index, `git update-index --add --cacheinfo "<mode>,<blob>,<path>"` per file (`--add` for a path missing from HEAD's tree), assert the new tree differs from `OLD^{tree}`, one `commit-tree`, one `update-ref`, then `git reset -q -- <every path>`.
- `commit-tree` skips commit hooks. Run the repository's own lint and format checks yourself, scoped to your paths (or whole-repo and filtered by path prefix); where the repository has no hooks, verify by readback.
- Report what you committed and that the other actor's edit was left uncommitted and untouched.

## Building the candidate

The candidate blob is HEAD's text plus exactly your lines, never the working copy. Then prove the working copy differs from it only by the expected foreign edit. The builder above covers one inserted line beside one foreign line; the bullets below adapt the assertions to other shapes.

- Anchor on a line that exists in HEAD's version (a unique prefix), never on a working-tree line number: foreign lines shift the numbering. Assert the anchor and your line each match exactly once.
- Foreign additions only: compare line multisets (`sorted(work) == sorted(candidate + foreign)`) so nothing is dropped or invented. This assertion fails, and nothing is committed, when their edit duplicates an existing line (blank lines, repeated headings) or modifies one; build explicitly from HEAD plus your text in that case.
- Foreign modifications or deletions: take `difflib.SequenceMatcher(None, head_lines, candidate_lines, autojunk=False).get_opcodes()` and accept only named regions (an insert directly after your anchor, a span between your own section headings, a replaced named placeholder line); raise on anything else.
- difflib can pair a blank separator line with either side of your inserted block (2026-10-16). Check the block's first non-blank line rather than `work[j1]`. When your block itself contains blank lines, opcodes also mispair (a 118-line addendum reported one `replace` plus an `insert`); use positional checks instead: `new[:i] == head[:i]` and `new[i + len(block):] == head[i + 1:]`.
- Append-only shared file with many foreign entries: append your block at the end of the working file, build the candidate as HEAD's text plus your block, locate the block by its unique heading, assert none of its lines are in HEAD, and assert multiset containment of every candidate line in the working file. When your entries are interleaved with foreign or already-committed ones, take all-insert opcodes and classify each insert by its heading against explicit lists of yours and theirs, inserting only yours at their HEAD positions.
- Untracked shared file (`git show HEAD:<path>` fails): commit the working content minus their lines, assert that exactly your lines remain, and expect `git status` to show the file modified with only their lines in the diff.
- A file that is wholly yours: still assert the exact opcodes you expect, so a foreign edit that arrived since you last looked fails the assertion instead of riding along.
- A new note or file: assert `git ls-files -- <path>` is empty, then commit the working content as is.

## Failure modes

- Run builders from stdin or from a private scratch directory, never as a loose script in a shared system temp directory: the script's directory is first on `sys.path`, and a stray `types.py` there shadowed the standard library and killed a builder at `import difflib` (2026-10-15). Under `set -e` it stopped before `update-ref`, so nothing was committed.
- Do not filter the leftover diff with `grep -E '^[-+][^-+]'`: a Markdown bullet adds a `+- ...` line that the pattern drops, so grep matches nothing and exits 1 under `pipefail` after the commit has already landed. Print the diff unfiltered, or use `grep -E '^[-+]' | grep -v -E '^(\+\+\+|---) '`.
- After any failure past `update-ref`, run `git log -1` before rerunning. A single-file builder's multiset assertion then fails on rerun, so it cannot commit twice; a multi-file builder needs the new-tree check above.
- If `update-ref` refuses because the branch moved, someone committed at the same time (observed 2026-10-15, minutes before a build). Re-read HEAD and rebuild; never force the update.
- If the path is not a regular non-executable file, the mode from `git ls-files -s` carries it; never hard-code `100644`.
