# AGENTS.md

This file provides guidance for agentic coding agents operating in this dotfiles repository.

## Repository Overview

This is a dotfiles repository managed with **GNU Stow** for symlinking and **Nix Flakes** (nix-darwin + home-manager) for package management on macOS. All configurations must be compatible with both macOS and Linux unless explicitly noted (Nix configurations are macOS-only).

## Build Commands

### Nix (macOS Only)

```bash
# Build system configuration (darwin-configuration.nix)
nix build '.#darwinConfigurations.swe.system' --print-build-logs
sudo ./result/bin/darwin-rebuild switch

# Build user environment (home.nix)
home-manager switch --flake .#swe

# Update flake inputs
nix flake update

# Garbage collection
nix-collect-garbage -d
```

### Stow (All Platforms)

```bash
# Symlink a package to home directory
stow <package>

# Restow a package (after modifications)
stow -R <package>

# Dry run
stow -nv <package>

# Unstow a package
stow -D <package>
```

Available packages: `banners`, `bin`, `claude`, `figlet`, `ghostty`, `git`, `helix`, `neovim`, `tmux`, `zellij`, `zsh`

### Running a Single Test

This is a dotfiles repository - there are no traditional tests to run. For Nix configurations:

```bash
# Evaluate flake (syntax check only)
nix eval '.#darwinConfigurations.swe.system' --dry-run

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
├── flake.nix              # Nix flake entry point
├── darwin-configuration.nix  # nix-darwin system config
├── home.nix               # home-manager user config
├── neovim/.config/nvim/  # Neovim config (XDG layout)
├── zsh/                   # Zsh configuration
├── tmux/                  # Tmux configuration
├── git/                   # Git configuration
├── helix/                 # Helix editor config
├── ghostty/               # Ghostty terminal config
└── bin/                   # Custom scripts
```

## Editor Configuration

This repository includes Neovim configuration with:
- **Plugin manager**: lazy.nvim
- **Leader key**: `,` (comma)
- **Indentation**: Tabs (2 chars)
- **Local dev**: Plugins in `~/.local/src` load locally

Key files:
- `neovim/.config/nvim/lua/cfg/lazy.lua` - Plugin imports
- `neovim/.config/nvim/lua/cfg/general.lua` - Core settings
- `neovim/.config/nvim/lua/lsp/` - LSP configurations

## Common Tasks

### Adding a Neovim Plugin

1. Create `lua/core/` or `lua/ui/` file with lazy.nvim spec
2. Add `require("core/your-plugin")` to `cfg/lazy.lua`
3. Restow: `stow -R nvim`

### Modifying Nix Packages

1. Edit `flake.nix` for inputs, `home.nix` for user packages, or `darwin-configuration.nix` for system packages
2. Test build: `nix build '.#darwinConfigurations.swe.system' --print-build-logs`
3. Activate: `sudo ./result/bin/darwin-rebuild switch`

### Adding a New Stow Package

1. Create top-level directory with target structure
2. Add to README.md table
3. Test: `stow -nv <package>`
4. Apply: `stow <package>`
