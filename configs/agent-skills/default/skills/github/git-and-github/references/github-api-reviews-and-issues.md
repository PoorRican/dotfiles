# GitHub API reviews and issues

Scope: Distinct GitHub issue, conversation, formal-review and inline-thread surfaces.

## Comments, reviews and threads

- PR conversation comments, formal reviews and inline review threads are separate GitHub surfaces. `gh pr view --json comments` does not report review-thread resolution or outdated state. (src: github-open-pr-feedback-audit, 2026-07-26; github-code-review, 1969-12-31)
- Inline review comments anchor to the PR head commit; `line` refers to the new file version, while a comment on a deleted line uses `side: LEFT`. Multiple inline comments can be submitted in one atomic review request. (src: github-code-review, 1969-12-31)
- A visible inline comment is not automatically outstanding: unresolved-current threads, unresolved-outdated threads, resolved threads, formal reviews and top-level conversation comments are distinct states or surfaces. (src: github-open-pr-feedback-audit, 2026-07-26)
- Broadly nested GraphQL traversals can fail with `MAX_NODE_LIMIT_EXCEEDED`; modest per-connection bounds reduce the chance of an unnecessarily large nested result. (src: github-open-pr-feedback-audit, 2026-07-26)
- A GraphQL review-thread ID and a REST root-comment database ID are different identifiers. A descendant supersedes feedback only when its code concretely fixes the behavior or removes the criticized path; a resolution reply should cite that descendant evidence. (src: github-stacked-review-relevance-resolution, 2026-07-29)
- Review-thread relevance is judged against both the revision the reviewer saw and the current stack tip; descendant code may supersede an issue without erasing whether the original report was valid. (src: github-stacked-review-relevance-resolution, 2026-07-29)
- PR conversation comments retrieved with `gh pr view --json comments` differ from a known inline comment retrieved through the pull-request review-comments API. (src: get-pr-comments, 2026-06-19)

## Issues and checks

- GitHub's `/issues` list endpoint also returns pull requests; results need to be filtered for entries containing `pull_request` before they are treated as issues. (src: github-issues, 1969-12-31)
- `Closes #N`, `Fixes #N` and `Resolves #N` in a PR body link an issue for automatic closure when the PR merges. (src: github-issues, 1969-12-31)
- Commit statuses and Actions check-runs are distinct surfaces; either alone may not explain a PR's complete CI state. (src: github-pr-workflow, 1969-12-31)
- GitHub's REST API supports direct PR merge, while enabling auto-merge uses GraphQL. (src: github-pr-workflow, 1969-12-31)
