# Patch artifacts

Scope: Capturing and checking diffs without staging the working files.

- When combining captured diffs, retain a newline between diffs and at EOF; captured terminal output may strip it. Include intended new files, for example by capturing `git diff --no-index /dev/null <new-file>` separately; it exits 1 when differences exist. Inspect the resulting paths and binary content before combining patches.
- Check the artifact with `git apply --reverse --check <patch>` against the edited tree, or `git apply --check <patch>` against the clean baseline. These check applicability, not that the artifact includes every intended change. (exercised on a disposable repository)
