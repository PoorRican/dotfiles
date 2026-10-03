# Hermes profiles and Nix

Scope: Hermes profile ownership and Nix/Home Manager configuration traps that are not a substitute for the current profile contract.

## Current profile contract

- The [dotfiles Hermes README](/home/swe/dotfiles/configs/hermes/README.md) documents current profile composition and the boundary between Nix-owned configuration and runtime state; older profile-wiring recipes can conflict with that contract. (src: hermes-nix-profile-extension; 2026-09-04)
- A divergent live skill copy is a private candidate only when its content is absent from both the installed package and locked optional-skill baseline; an older copy from either baseline is not new authorship by itself. (src: hermes-profile-nix-conversion; 2026-09-08)

## Nix and daemon configuration

- Nix `//` is a shallow merge: overriding a nested attrset such as `Unit` replaces that entire attrset and can silently drop sibling keys. Is the changed leaf being parameterized or otherwise merged at the intended depth? (src: hermes-nix-profile-extension; 2026-09-04)
- An active service and a deployed config file do not prove that the daemon parsed the config; a message such as “found 0 rules” can indicate a grammar mismatch rather than a bad rule value. (src: home-manager-daemon-config-verification; 2026-09-04)
- Source-level Nix does not reveal the resolved unit after merges, and a correctly rendered unit does not prove the daemon accepted its own config. Which consumer boundary is still unobserved: resolved Home Manager output, systemd's parsed unit, or the daemon's parsed rules? (src: home-manager-daemon-config-verification; 2026-09-04)
- Reading a systemd value equal to the manager's default cannot distinguish an applied setting from an ignored one; a non-default value provides that distinction. (src: home-manager-daemon-config-verification; 2026-09-04)

## Canonical ownership

Canonical doc: [Hermes profiles](/home/swe/dotfiles/configs/hermes/README.md) — owns the current adapter, profile composition, configuration ownership, and runtime-state contract.
