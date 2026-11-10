# Worktree cloning and Gitignore research

Use this procedure when a coding harness produces unexpectedly large or recursively nested workspaces. Establish traversal behavior before attributing old copies or proposing cleanup.

## 1. Freeze scope and establish release identity

Separate investigation, fixture execution, configuration changes and deletion authority. When harness execution is prohibited, resolve its executable without invoking it, record size and SHA256, and match platform-specific official release-asset metadata. Pin the corresponding source commit. Query current stable separately; neither a remembered version nor the newest documentation identifies the installed implementation. A digest match identifies current disk bytes, not a historical process or loaded addon.

## 2. Trace each creation entry point independently

Follow shell-command interception, manual worktree creation, session/PR workspaces and isolated task creation through to their materialization call. Record each controlling key, default, source root, destination resolver and backend candidates. Inspect interception before assuming that a literal `git worktree add` inside the harness executes ordinary Git; a rewrite can change checkout semantics while preserving familiar command spelling.

Read backend selection as code, not a label. Determine whether a configured backend is mandatory or a preference with fallbacks. Manual clone selection and task isolation can use different filters, so a Git-backed fallback preference is not a strict no-copy guarantee.

## 3. Inspect traversal and filesystem semantics

Follow the exclusion list through every recursive call. Check root `.git`, nested `.git` files and directories, ignored workspace forests, destination containment, symlink behavior and filesystem boundaries. Do not infer Gitignore enforcement from an earlier repository-discovery filter; a filesystem copier can deliberately carry ignored caches and then copy ignored worktrees too.

Distinguish real Btrfs subvolume snapshots, per-file FICLONE reflinks and ordinary copies. Verify snapshot source-root requirements and the unavailable/fallback path; residing on Btrfs does not establish which backend ran. Reflinks can share file data while materializing separate inode and directory metadata.

Evaluate source pollution separately from destination placement. An external destination avoids encountering the new destination during traversal, but does not exclude old nested worktrees already inside the source.

## 4. Exercise the actual selection code with a tiny fixture

Compile or load the pinned walker in a new owned fixture namespace with a simple ordinary-copy callback. Seed only synthetic data:

- A root `.git` entry.
- A nested repository's `.git` entry.
- An ignored worktree containing another worktree.
- An ignored cache directory.

Run the caller's actual exclusion policy against an external destination and assert the exact retained and omitted paths. Add an explicit workspace-root exclusion as a positive control; check that root-only exclusions do not silently become all-depth exclusions. Preserve source digests, compile/run statuses and assertions. Use a fresh directory for each replay because exclusive-create fixtures must not overwrite prior evidence. Do not attempt unbounded self-destination recursion to prove a selection defect.

Label this result precisely: actual-walker selection with an ordinary-copy callback is not a kernel reflink test, Btrfs snapshot test or full-harness reproduction.

## 5. Corroborate without overstating attribution

Reuse timestamped complete namespace censuses and bounded no-follow root identities before commissioning another giant scan. Distinct directory inodes can reject symlink-alias explanations, but cannot distinguish reflinking from deep copying. Keep root metadata equality separate from descendant/content stability. Entry counts and repeated path components corroborate amplification; they do not establish a particular historical creator or yield a metadata-byte reclamation forecast.

## 6. Derive prevention from independent controls

Verify each setter against the installed parser and typed declarations. Distinguish defaults, persisted global values, project overrides and runtime-effective values; inspect only the required keys rather than dumping private configuration.

For OMP implementations that expose the following keys, verify their semantics before proposing these commands:

    omp config set worktree.clone false
    omp config set task.isolation.enabled false

The clone control and automatic task-isolation gate are independent. Explicitly setting isolation off may only confirm its existing default. Disabling automatic isolation also changes concurrency semantics; retain separately managed workspaces for concurrent writers.

Do not apply investigation-only proposals. When approved, verify effective values in the relevant scopes and account for already-running tasks separately; persisted settings neither stop old jobs nor remove old namespaces.

Create clean future workspaces through actual plain-Git checkout materialization outside source checkouts. Do not copy or reflink a polluted workspace to seed them; recreate ignored caches and dependencies deliberately.

## 7. Verify fixes and report separate conclusions

Check proposed fixes using actual merge state, ancestry/release inclusion and the affected tagged walker. A comment claiming a fix or an unrelated baseline-discovery change is not evidence that copying is prevented.

Report four separate outcomes: installed mechanism, historical attribution, future prevention and existing-copy reclamation. Delegate filesystem preservation/removal proof to the cleanup workflow; source inspection and fixture success cannot authorize deletion. Preserve unique work and external Git administration because copied `.git` pointers can alias originals.
