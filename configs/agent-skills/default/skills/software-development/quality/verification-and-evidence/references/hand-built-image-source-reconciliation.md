# Hand-built image source reconciliation

Scope: a live workload runs an image built by hand from uncommitted source (a "-dirty" tag, or a digest no pipeline published). Prove what the source was by reproducible rebuild, commit it cleanly, and pin a pipeline-built image by digest. Rollout steps need the owner's authorization.

## The trap

- The only record of the source is an uncommitted pin in some checkout. Applying manifests from the main branch silently rolls the workload back to older code, and if that checkout is lost the image becomes unrebuildable. (src: image-provenance-reconcile; 2026-10)

## Establish what is live, read-only

- Collect the running images and container image IDs (digests), the managed-fields managers and times and controller-revision timestamps (a patch-style manager means someone rolled out manually), registry metadata for the image (creation time, labels, build-arg history), and the build identity embedded in the binary itself, read with `strings`. (src: image-provenance-reconcile; 2026-10)

## Prove the source; do not infer it

- Find the base checkout that held the uncommitted work (modification times earlier than the image creation time), rebuild the binaries with the image's recorded build arguments, and require byte-identical SHA-256 against the binaries inside the running container. Compare any sidecar tree by path, size, and hash too. (src: image-provenance-reconcile; 2026-10)
- A tag suffix hash that cannot be explained is not a blocker when the binaries match, but report it. Re-derive the rebuild command from the repository's current build script rather than copying a recorded command; old build targets may no longer exist. (src: image-provenance-reconcile; 2026-10)

## Commit cleanly, then pin by digest

- Export the working changes with `git diff HEAD --binary > patch`, create a worktree from the main branch beside any path-dependency siblings, apply with `git apply --3way` plus the untracked files by name, and check that intervening main-branch changes do not touch the binary's dependency tree (dependency-tree output, `git diff --name-only`). Update documentation that describes the dirty state, and land with a merge commit. (src: image-provenance-reconcile; 2026-10)
- Wait for the pipeline run on the main branch to publish the image, resolve its digest from the registry, and pin by digest rather than by tag. After the owner-authorized apply, verify the pods are Ready, the container image ID matches the pinned digest, the embedded build SHA is the expected one, and safety-relevant runtime switches are unchanged. Park the superseded uncommitted pin in a labelled stash and record the evidence in the pull request. (src: image-provenance-reconcile; 2026-10)
