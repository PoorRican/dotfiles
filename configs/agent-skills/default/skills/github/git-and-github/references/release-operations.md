# Release operations

- Identify the intended commit, remote and actual PR base; preserve unrelated dirty work. Authentication or remote reachability alone does not establish permission to write.
- Before publishing a tag, distinguish an absent remote ref from a failed query. Compare an existing tag's peeled commit with the intended commit; do not overwrite a conflicting tag. Branch, annotated tag object and peeled commit are separate remote refs to verify.
- A successful branch push does not prove a tag push, and a tag does not prove a release or default-branch integration. Read back each requested artifact independently. `gh release create --verify-tag` prevents creating a missing tag implicitly.
- Report the exact failed operation and separately verified remote artifacts; do not infer remote completion from local state.

Inspect the local and remote tag with `git tag --list "$TAG"` and `git ls-remote --tags origin "refs/tags/$TAG" "refs/tags/$TAG^{}"`. For an annotated tag, compare the peeled commit to the intended commit; a failed query is not evidence of absence. When authorized, create it with `git tag -a "$TAG" -m "$TAG" "$COMMIT"`, verify `git rev-parse "$TAG^{commit}"`, and push the branch and tag separately. Read back the exact remote OIDs.

For a requested PR, `gh pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body "$BODY"` avoids automatic push or fork selection; verify its head and base. For a requested release, verify its tag and state with `gh release view "$TAG" --json tagName,isDraft,isPrerelease,url`. A tag, PR and release are distinct artifacts.
