# Commit splitting and hooks

## Splitting a moving tree

- A commit plan is a snapshot: another writer may commit planned paths or add new ones. Refresh the base and status; compare the planned and live path sets in both directions before staging explicit paths.
- Build each intermediate tree with its required consumers, tests and target registrations. A manifest that registers a file not yet committed can break an intermediate build even if a dependency declaration alone would not. Compare the final reconstructed tree with the intended final content; passing tests alone does not establish equality.
- A piped commit can mask a hook failure if the pipeline returns the last command's status. Stop a multi-commit sequence at its first failure, and inspect actual history before retrying: earlier commits may already have succeeded.
- A hook that formats and re-stages whole paths can absorb unrelated unstaged hunks. Inspect the staged and committed content after hooks.

## Hook visibility

- A project-mode pre-commit hook can see untracked files while tracked unstaged edits are stashed; untracked consumers may therefore fail against a partial staged tree. An unstaged ignore rule can also change which files the hook sees.
- To attribute such a failure, construct a detached snapshot of the staged tree without moving refs and run the failing check there. Confirm the interpreter and imported module resolve to that snapshot, not a different checkout. A clean snapshot attributes the failure but does not authorize bypassing the hook; coordinate with the other writer rather than moving or staging their files.
- Worktrees share the repository's common hooks directory. Installing a hook from a temporary worktree can leave it pointing to an interpreter that disappears with that worktree.
- Check whether a failing gate concerns the proposed change before attributing it; report pre-existing failures rather than silently changing unrelated code.
