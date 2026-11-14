---
name: conventional-commits
description: Use when writing Conventional Commit messages or grouping changes into commits.
---

# Conventional Commits

Conventional Commits encode change type, optional scope and breaking changes in a machine-readable message. Follow the repository's conventions and the [specification](https://www.conventionalcommits.org/en/v1.0.0/).

Group changes into coherent commits that preserve useful, independently understandable history; tests and documentation often belong with the behavior they support. Order dependent commits so intermediate states remain meaningful. Use `!` after the type or scope, or a `BREAKING CHANGE:` footer, to mark a breaking change.

## Workflow

1. Analyze workspace state with `git status`, `git diff --stat`, and `git diff --staged --stat`.
2. Review actual changes for each modified file: `git diff -- <file>` for unstaged changes and `git diff --staged -- <file>` for staged changes. Account for untracked files as well.
3. Group changes logically. Feature code and its unit tests, or a migration and its model changes, may form one atomic commit; unrelated fixes can be separate.
4. Determine commit order from dependencies: infrastructure or core functionality may need to precede dependent changes. Ask the user if grouping or ordering is genuinely ambiguous.
5. When authorized to commit, stage each intended group with `git add <files>` and commit with `git commit -m "<type>(<scope>): <description>"`. Preserve unrelated staged or unstaged work.

Use a specific, imperative description. When needed, separate the body with a blank line and explain what and why; use a footer to describe breaking changes or reference an issue.
