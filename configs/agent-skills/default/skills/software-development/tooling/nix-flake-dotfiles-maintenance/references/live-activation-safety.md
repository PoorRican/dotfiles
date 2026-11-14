# Activation safety

## Distinguish states

Report repository content, evaluation, built generation, applied generation and live service behavior separately. A successful evaluation or commit does not make a desktop change active; a running process may still use an older configuration. When removing a desktop profile, inspect imports, applied links and live services separately from dormant files, and preserve needed replacements.

## Managed files

Home Manager can build successfully but refuse activation because an unmanaged file would be clobbered. Compare the file with the intended managed source and preserve local changes before moving it to a backup and switching. Managing an entire Neovim config directory as a symlink while Home Manager also generates a file inside it can cause an installation conflict; choose one owner for the tree or its individual files. Multiple package providers of the same binary can likewise conflict in the generated profile.

Git may read both a managed XDG configuration and an unmanaged legacy config; inspect both when effective URL rewrites or credential helpers differ from the managed file.

## Remote switch procedure

1. Establish which source reproduces the running generation:
   `nix eval --raw '.#nixosConfigurations.<host>.config.system.build.toplevel.outPath'`
   versus `readlink -f /run/current-system`. Check the actual deployment
   checkout and relevant worktrees; if none matches, stop and resolve the
   provenance mismatch before risking a reversion of a live change.
2. Build the candidate. Compare `nix store diff-closures` for the running and
   candidate systems, diff generated `etc/sysctl.d` and, when touched,
   `sshd_config` and `fstab`, then inspect dry-activation output. A listed
   `systemd-sysctl.service` restart can reset runtime-critical forwarding:
   check the full candidate sysctl set, not just the edited key.
3. Keep an independent SSH session open. Before authorized route or firewall
   changes, arm a rollback on each affected host, for example
   `systemd-run --on-active=180 <absolute-path-to-rollback-command>`;
   transient units have a minimal PATH. Cancel only after verification.
4. Verify the affected workload from a peer, including forwarding and DNS
   where applicable, not just a reachable host. If forwarding is unexpectedly
   disabled, restore it and fix the declaration; do not restart
   `systemd-sysctl` as a diagnostic probe.
