# Release operations

Scope: Evidence-based branch, tag, pull request and release operations. Owner authorization is required before remote mutation.

## Preflight and tags

- Inspect `git status --short --branch`, `git log -1 --oneline`, `git remote -v` and the intended commit; preserve unrelated dirty work. `git symbolic-ref --quiet --short refs/remotes/origin/HEAD` is only a hint about the base: confirm the actual PR base. `gh auth status` and `git ls-remote origin` do not prove remote write authorization.
- Inspect `git tag --list "$TAG"` and `git ls-remote --tags origin "refs/tags/$TAG" "refs/tags/$TAG^{}"`; distinguish an absent ref from a failed query. Compare an existing tag's peeled commit with the intended commit before reuse; do not overwrite a conflicting tag. Where required, create an annotated tag with `git tag -a "$TAG" -m "$TAG" "$COMMIT"`, then inspect `git rev-parse "$TAG^{commit}"`.
- When authorized, push the intended branch and tag separately, for example `git push -u origin HEAD` and `git push origin "refs/tags/$TAG:refs/tags/$TAG"`. Read back the exact remote branch OID, tag object and peeled commit and compare them with the expected local values. A branch push does not establish tag success. (tag creation, separate pushes and readback exercised against a disposable local remote)

## PR, release and reporting

- Create a PR only if requested, with explicit `gh pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body "$BODY"`; verify its head and base independently. `--head` skips the CLI's automatic push or fork behavior. For a requested release, `gh release create "$TAG" --verify-tag` prevents implicit creation of a missing remote tag; inspect `gh release view "$TAG" --json tagName,isDraft,isPrerelease,url` and verify the requested state. A tag, PR and release are distinct artifacts. (CLI help checked; remote operations not re-run)
- On failure, report the branch, commit SHA and subject, local tag and target, exact failed operation, separately verified remote artifacts and remediation appropriate to the error. Do not infer remote completion from local artifacts or generalize an authentication failure to an outage without evidence. (method)
