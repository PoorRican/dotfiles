# AGENTS.md

This file provides guidance for agentic coding agents operating in this dotfiles repository.

## Repository Overview

This is a dotfiles repository managed with **Nix Flakes** (nix-darwin + home-manager) for package management on macOS and Linux. Configurations live under `configs/` and are deployed via home-manager modules.

## Build Commands

### Home-Manager (User Environment)

```bash
home-manager switch --flake .#mbp      # macOS
home-manager switch --flake .#dgx      # DGX (Linux)
home-manager switch --flake .#server   # Linux server
```

### Nix-Darwin (macOS System Config)

```bash
nix build '.#darwinConfigurations.swe.system' --print-build-logs
sudo ./result/bin/darwin-rebuild switch
```

### Maintenance

```bash
nix flake update          # update all inputs (triggers full rebuild)
nix-collect-garbage -d    # garbage collection
```

### Running a Single Test

This is a dotfiles repository - there are no traditional tests to run. For Nix configurations:

```bash
# Evaluate flake (syntax check only)
nix eval '.#homeConfigurations.mbp.activationPackage' --no-build

# Check Nix file syntax
nix-instantiate --parse flake.nix
```

## Code Style Guidelines

### General Principles

- **Cross-platform compatibility**: All configs (except Nix/home-manager) must work on both macOS and Linux
- **XDG Base Directory**: Use XDG-compliant paths (e.g., `~/.config/nvim` not `~/.nvim`)
- **Minimalism**: Prefer lean configurations over heavy frameworks

### Shell (Zsh)

- Use `zsh` syntax, not bashisms (this repo targets zsh)
- Use `#!/usr/bin/env zsh` shebang for scripts
- Prefer explicit subshells `(...)` over `$(...)` where appropriate
- Quote variables: `"$var"` not `$var`
- Use `local` for function-local variables

### Nix

- Follow [Nixpkgs conventions](https://nixos.org/manual/nixpkgs/stable/)
- Use `lib.mkIf`, `lib.mkWhen` for conditional config
- Prefer overlays for package modifications
- **Python overrides**: Use `doInstallCheck = false` (not `doCheck`) to skip tests
- **Python interpreter**: Target specific version (e.g., `python313`) not `python3`
- Use `pythonXYZ.override { packageOverrides = ... }` not `pythonPackagesExtensions` for overrides
- **Config sources**: Nix modules receive `dotfiles` via `extraSpecialArgs` — use `dotfiles + "/configs/..."` to reference config files (no relative `../../` paths)

### Lua (Neovim)

- 2-character tab indentation (no spaces)
- Use lazy.nvim plugin spec format
- Follow Neovim conventions: `require("module")` for imports
- Use descriptive keymap descriptions

### Git Commits

- Use conventional commits: `feat(nvim):`, `fix(zsh):`, `chore(tmux):`
- Stage only changed files: `git add <file>` not `git add .`
- Group by module

### Error Handling

- Fail fast on critical errors
- Use defensive checks for optional dependencies
- Provide helpful error messages that explain what's wrong and how to fix it

### Naming Conventions

- Files: lowercase with hyphens (e.g., `init.lua`, `lazy.lua`)
- Directories: lowercase (e.g., `lua/cfg/`)
- Nix attributes: snake_case (e.g., `enableFlakes`)
- Lua functions: camelCase

## Project Structure

```
.
├── configs/                     # app configurations (deployed by home-manager)
│   ├── ghostty/                 # Ghostty terminal config
│   ├── git/                     # Git configuration
│   ├── helix/                   # Helix editor config
│   ├── neovim/                  # Neovim config (XDG layout)
│   ├── tmux/                    # Tmux configuration
│   ├── zellij/                  # Zellij multiplexer config
│   └── zsh/                     # Zsh shell configuration
├── assets/                      # static resources
│   ├── banners/                 # custom banners
│   ├── figlet/                  # figlet fonts
│   └── fonts/                   # imported fonts
├── bin/                         # custom scripts
├── claude/                      # Claude Code configuration
├── nix/                         # nix infrastructure
│   ├── hosts/                   # per-host configurations
│   ├── modules/                 # home-manager modules
│   ├── profiles/                # composable package sets
│   └── layers/                  # cross-cutting feature layers
├── docs/                        # documentation
├── flake.nix                    # nix flake entry point
└── darwin-configuration.nix     # nix-darwin system config
```

## Editor Configuration

This repository includes Neovim configuration with:
- **Plugin manager**: lazy.nvim
- **Leader key**: `,` (comma)
- **Indentation**: Tabs (2 chars)
- **Local dev**: Plugins in `~/.local/src` load locally

Key files:
- `configs/neovim/lua/cfg/lazy.lua` - Plugin imports
- `configs/neovim/lua/cfg/general.lua` - Core settings
- `configs/neovim/lua/lsp/` - LSP configurations

## Common Tasks

### Adding a Neovim Plugin

1. Create `lua/core/` or `lua/ui/` file with lazy.nvim spec
2. Add `require("core/your-plugin")` to `cfg/lazy.lua`
3. Rebuild: `home-manager switch --flake .#mbp`

### Modifying Nix Packages

1. Edit the relevant `nix/` module or profile
2. Rebuild: `home-manager switch --flake .#mbp`

### Adding a New Config

1. Create directory under `configs/` with target XDG structure
2. Create `nix/modules/<name>.nix` — use `{ dotfiles, ... }:` to receive the repo root
3. Import the module from the appropriate host config
4. Rebuild: `home-manager switch --flake .#mbp`
