# Live activation safety (NixOS generations)

Scope: switching a running NixOS host to a new generation when the host carries traffic or services you must not interrupt (a router, a Kubernetes node, a remote machine reachable only over SSH). The procedure assumes the owner has authorized the activation itself.

## Provenance: what is running versus what you are about to build

- Find the revision that builds to the running generation first: `nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.outPath` must equal `readlink -f /run/current-system`, in the primary deploy checkout and in every git worktree on the host. If none matches, stop: switching would revert someone's live, uncommitted activation. Never trust a local workstation mirror of the deploy repository; fetch and compare against the real remote. (src: nixos-live-switch; 2026-10)

## Build, diff, dry-activate

- Build first, then compare: `nix store diff-closures` between the running and new system, a diff of `etc/sysctl.d` (and `sshd_config`, `fstab` when touched), and a dry-activate. Every difference must be yours. (src: nixos-live-switch; 2026-10)
- Treat `systemd-sysctl.service` in dry-activate output as a red flag. Dry-activate lists the units it will restart, not what they re-apply, and a restart re-applies the declared sysctl set from scratch: require every runtime-critical key (for example `net.ipv4.conf.all.forwarding = 1`) to be present in `$NEW/etc/sysctl.d`. One switch that only added a single sysctl key restarted the unit, reset forwarding to 0, and cut all off-host pod traffic through the node for minutes while the node stayed Ready and host ping stayed green. (src: nixos-live-switch; 2026-10-26)
- A strict reverse-path filter drops a source arriving on an unexpected interface, so a legitimate peer may need explicit RETURN exceptions. `iptables-nft -C ... -i <if>` once false-matched a rule for another interface; list the chain after every insert instead of trusting the check. (src: nixos-live-switch; 2026-10-26)

## Preserve access and services across the switch

- Commit only your own files on the host worktree branch, and assert that the committed tree rebuilds to the same `$NEW` you tested. Keep an independent SSH session open for the whole switch. (src: nixos-live-switch; 2026-10)
- Before any route or firewall change, arm rollback timers on each affected host: `systemd-run --on-active=180 <absolute path to the rollback command>` (absolute binary paths, because the transient unit has a minimal `PATH`). Stop them only after verification passes. (src: nixos-live-switch; 2026-10)
- Verify at the workload level after activation, not just the host: forwarding (`net.ipv4.ip_forward`) reads 1, service endpoints answer from a peer host, the count of healthy scrape targets is as expected rather than a single digit, and in-cluster DNS resolves. Never restart `systemd-sysctl` as a probe; if forwarding reads 0, set it at once and then fix the source. Link the repository's own runbook for the exact commands rather than copying them. (src: nixos-live-switch; 2026-10-26)

## Landing the change

- Land on the main branch by `git cherry-pick -x` onto a branch off the freshly fetched remote main, run `nix-instantiate --parse` on the changed files, and merge by pull request with a merge commit. In the PR state the generation number, the store path, the source branch, and whether main still fails to reproduce the live system. (src: nixos-live-switch; 2026-10)
