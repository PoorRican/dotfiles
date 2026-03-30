# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a dotfiles repository which manages various configurations and CLI utilities, and supports both macOS and Linux environments.

An XDG config layout is used for sanity. Package management is handled with `home-manager` on both macOS and Linux, while nix-darwin remains macOS-only. Configs are deployed via home-manager modules that reference files under `configs/`.

### Repository Layout

```
.
├── configs/                # app configurations (deployed by home-manager)
│   ├── ghostty/
│   ├── git/
│   ├── helix/
│   ├── neovim/             # see configs/neovim/CLAUDE.md for details
│   ├── tmux/
│   ├── zellij/
│   └── zsh/
├── assets/                 # static resources
│   ├── banners/
│   ├── figlet/
│   └── fonts/
├── bin/                    # custom binaries / scripts
├── claude/                 # claude code configuration
├── nix/                    # nix infrastructure (hosts, modules, profiles, layers)
├── docs/                   # helpful documents
├── .old/                   # archived, legacy configurations
├── flake.nix               # nix flake entry point
└── darwin-configuration.nix
```

## High-level Module Notes

- Neovim is configured with lazy-nvim and comprehensive treesitter grammar support
- Aside from the `home-manager`, and nix flakes, ALL configurations MUST be compatible for BOTH macOS AND Linux.
- When possible, defer to XDG home configs as a universal template.

## Git Commit Conventions

- Group commits by module (e.g., `feat(nvim):`, `feat(nix):`, `feat(zsh):`, `feat(ghostty):`)
- When committing, only stage files you changed. Ignore unrelated unstaged changes.

## `home-manager` Config

### Nix Overlay Gotchas

- **Python package test overrides**: Python packages in nixpkgs run tests via `installCheckPhase` (`doInstallCheck`), NOT `checkPhase` (`doCheck`). Override `doInstallCheck = false` to skip failing tests.
- **Python interpreter targeting**: Override the specific interpreter (e.g., `python313`) not `python3`. Packages reference the concrete version, so `python3.override` won't propagate.
- **`pythonPackagesExtensions`** is for adding new packages to the set, not overriding existing ones. Use `pythonXYZ.override { packageOverrides = ... }` instead.
- **`nix flake update` risks**: Updating can fix one issue but introduce new build failures. Prefer targeted overlays over broad updates.
- The `flake.nix` currently has a `setproctitleOverlay` that disables `doInstallCheck` for `python3.13-setproctitle` (segfaults in fork tests on aarch64-darwin).

### Nix File Structure

- **flake.nix**: Main entry point defining inputs (nixpkgs, nix-darwin, home-manager) and per-host homeConfigurations
- **darwin-configuration.nix**: System-wide macOS settings managed by nix-darwin (system packages, preferences, user accounts)
- **nix/hosts/**: Per-host configurations that compose profiles and modules
  - `mbp.nix` — macOS (aarch64-darwin, user: swe)
  - `dgx.nix` — Linux DGX (x86_64-linux, user: sparky)
  - `server.nix` — Linux server (x86_64-linux, user: swe)
- **nix/profiles/**: Composable package sets (minimal, dev-core, dev-cloud, dev-extra, server, shell)
- **nix/modules/**: Individual program/tool configs — receive `dotfiles` via `extraSpecialArgs` to anchor config paths (ghostty, git, tmux, zellij, helix, zsh, neovim, hermes, claude-code, codex)
- **nix/layers/**: Cross-cutting feature layers (knowledge-tools)

### Agent Tools (claude-code, codex, hermes)

These tools are installed outside nixpkgs via their own installers. Each module in `nix/modules/` handles both config symlinks and installation via `home.activation` scripts. All three are imported and enabled by default in `nix/profiles/dev-extra.nix`.

The built-in home-manager modules for `programs.claude-code` and `programs.codex` are disabled (`disabledModules`) because the built-in modules copy files to the nix store, while ours use `mkOutOfStoreSymlink` for live editing from dotfiles.

**Per-host opt-out** — disable a tool in a host file:
```nix
# nix/hosts/dgx.nix
programs.codex.enable = false;
```

**Per-host hermes profile** — select a hermes config profile (defaults to `"default"`):
```nix
# nix/hosts/dgx.nix
programs.hermes.profile = "dgx";
```

**Auto-update on switch** — run a tool's own update command on every `home-manager switch`:
```nix
programs.claude-code.autoUpdate = true;  # runs `claude update`
programs.codex.autoUpdate = true;        # runs `bun install -g @openai/codex`
programs.hermes.autoUpdate = true;       # runs `hermes update`
```

Other notes:
- `darwin-configuration.nix` remains macOS-only
- The flake uses input following for consistency (all inputs use the same nixpkgs)
- System and user configurations are built separately for better isolation

### homeConfigurations

| Name     | System           | Username | Description       |
|----------|------------------|----------|-------------------|
| `mbp`    | aarch64-darwin   | swe      | macOS MacBook Pro |
| `dgx`    | x86_64-linux     | sparky   | Linux DGX         |
| `server` | x86_64-linux     | swe      | Linux server      |

### Configuration Details

- **Nix features**: Experimental features (nix-command, flakes) enabled
- **Package management**: System packages in darwin-configuration.nix, user packages via profiles/modules

### Common Commands

#### Building and Activating Configurations

**System configuration (darwin-configuration.nix changes):**
```bash
nix build '.#darwinConfigurations.swe.system' --print-build-logs
sudo ./result/bin/darwin-rebuild switch
```

**User environment (home-manager):**
```bash
home-manager switch --flake .#mbp      # macOS
home-manager switch --flake .#dgx      # DGX
home-manager switch --flake .#server   # Linux server
```

#### Maintenance Commands

**Garbage collection:**
```bash
nix-collect-garbage -d
```

**Update flake inputs:**
```bash
nix flake update          # updates ALL inputs — causes full rebuild on next switch
nix flake update nixpkgs  # updates only nixpkgs — still causes full rebuild
```

#### Update Workflow

- `home-manager switch --flake .#<host>` applies config changes using the **current** locked nixpkgs revision. Adding or removing a package only rebuilds what changed — fast and safe.
- `nix flake update` bumps ALL inputs to latest, which means every package may get a new version and trigger a full rebuild. **Don't run this unless you intentionally want version bumps.**
- To add a new package without touching versions: edit the relevant `nix/` module or profile, then run `home-manager switch --flake .#<host>`.
