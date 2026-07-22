---
name: get-pr-comments
description: Retrieve and filter GitHub pull request comments with the gh CLI.
---

# Get PR Comments

This skill provides instructions for retrieving comments from a GitHub Pull Request using the `gh` CLI. It can be used to fetch all comments, filter them, or retrieve specific comments by their ID.

## Overview

Use the `gh pr view` command with the `--json comments` flag to retrieve all comments for a given PR.

## Commands

### Fetch all comments for a PR
```bash
gh pr view <PR_NUMBER> --json comments --jq '.[] | {id: .id, body: .body}'
```

### Fetch comments for a specific PR with specific fields
```bash
gh pr view <PR_NUMBER> --json comments --jq '.[] | {author: .author.login, body: .body, createdAt: .createdAt}'
```

### Fetch a specific comment by ID
If you have a specific comment ID (e.g., `3432164182`), use the GitHub API:
```bash
gh api https://api.github.com/repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments/<COMMENT_ID>
```
*(Replace `<OWNER>`, `<REPO>`, `<PR_NUMBER>`, and `<COMMENT_ID>` with the actual values.)*

## Tips
- Use `-q` or `--jq` to format the output for easier reading (e.g., `jq 'sort_by(.createdAt) | .[]'`).
- If the PR is in a different repository than the current one, you may need to set the remote or use the full repository name in the `gh api` call.
- For large PRs, you might want to limit the output or filter by author.
