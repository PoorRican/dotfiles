# Worktree copying and exclusion research

Use this when a workspace creation tool produces unexpectedly large or recursively nested copies. Identify its installed implementation separately from current upstream; an executable digest establishes current disk bytes, not the identity of a historical process.

Trace each creation entry point through destination resolution, backend selection, and materialization. A harness can intercept a familiar Git command, and a configured backend can be a preference with fallbacks rather than a no-copy guarantee. Manual and automatically isolated workspaces may use different paths and filters.

Follow exclusions through every recursive call. Check root and nested Git metadata, ignored workspace trees and caches, destination containment, symlinks, and filesystem boundaries. A discovery filter does not prove a filesystem copier honors Gitignore. Placing the destination outside the source avoids traversing the new destination but does not exclude old nested worktrees already in the source.

Distinguish filesystem snapshots, per-file reflinks, and ordinary copies; filesystem type alone does not prove which ran. Reflinks may share file data while creating separate inode and directory metadata.

Where execution is permitted, exercise the actual pinned traversal and exclusion policy against a small synthetic fixture containing root and nested Git metadata, an ignored nested workspace, and an ignored cache. Compare exact retained paths and add an explicit exclusion as a positive control. An ordinary-copy callback tests walker selection, not kernel reflinks, snapshots, or the complete application. Avoid unbounded self-destination recursion.

Separate mechanism, historical attribution, prevention, and reclamation. Repeated path components and distinct inodes can corroborate amplification but do not identify the creator or distinguish reflinks from deep copies. Verify proposed controls against effective configuration and affected source; changing future settings does not stop existing jobs or remove old workspaces. Before deleting copies, preserve unique work and verify external Git administration: copied Git pointers can refer to the original repository.
