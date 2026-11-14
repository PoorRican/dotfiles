# GitHub API reviews and issues

- PR conversation comments, formal reviews and inline review threads are different surfaces. `gh pr view --json comments` does not establish thread resolution or outdated state. Inline comments may refer to an earlier reviewed commit rather than the current head.
- Enumerate and paginate threads and nested comments independently; large nested GraphQL queries can exceed node limits. A GraphQL thread ID is not the REST root-comment ID.
- Judge feedback against the revision reviewed and current tip: a descendant may fix the behavior without making the original finding invalid. Before retrying an uncertain reply, check whether it was already posted; read back replies and resolution state.
- Bind independent review evidence to the exact head and reviewer. Acknowledgement, passing checks, a resolved thread or an old-head review is not a current independent review.
- The GitHub issues list API also returns pull requests; filter entries with a `pull_request` field when collecting issues. Commit statuses and check-runs are distinct surfaces.
- A job can fail while its failing step is cancelled, leaving `gh run view --log-failed` without useful logs. Inspect job and step conclusions and full context before attributing or retrying a failure. A queued retry is not a pass.
- If acceptance depends on live state, code and migration evidence alone do not prove it; check that state or report the unverified condition.

Collect head, base, mergeability, reviews, conversation and inline comments, threads and checks. Compare enumerated thread and comment counts with totals; for REST aggregation, `gh api --paginate --slurp ENDPOINT | jq ...` wraps pages before filtering. Retain `pipefail`. Resolve a thread according to repository policy after verifying the published fix, then read back its state and check for new findings.
