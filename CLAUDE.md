# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a macOS dotfiles repository managed using Nix Flakes with nix-darwin and home-manager. The configuration follows a clean separation between system-wide and user-specific settings:

- **flake.nix**: Main entry point defining inputs (nixpkgs, nix-darwin, home-manager) and outputs for both system and user configurations
- **darwin-configuration.nix**: System-wide macOS settings managed by nix-darwin (system packages, preferences, user accounts)
- **home.nix**: User-specific environment managed by home-manager (user packages, program configurations)

The repository includes configuration directories for:
- **nvim/**: Neovim configuration with lazy-nvim plugin manager and treesitter support
- **zsh/**: Zsh shell configuration 
- **tmux/**: Terminal multiplexer configuration
- **git/**: Git configuration files

## Common Commands

### Building and Activating Configurations

**System configuration (darwin-configuration.nix changes):**
```bash
nix build '.#darwinConfigurations.swe.system' --print-build-logs
sudo ./result/bin/darwin-rebuild switch
```

**User environment (home.nix changes):**
```bash
home-manager switch --flake .#swe
```

### Maintenance Commands

**Garbage collection:**
```bash
nix-collect-garbage -d
```

**Update flake inputs:**
```bash
nix flake update
```

## Configuration Details

- **System**: Configured for aarch64-darwin (Apple Silicon)
- **Username**: swe (configured in flake.nix variables)
- **Nix features**: Experimental features (nix-command, flakes) enabled
- **Package management**: System packages in darwin-configuration.nix, user packages in home.nix
- **Development tools**: nodejs_22, bun, awscli2, google-cloud-sdk, pulumi configured in home.nix
- **CLI tools**: ripgrep, fd, bat, jq, gh, tmux, oh-my-zsh available

## Key Architecture Notes

- The flake uses input following for consistency (all inputs use the same nixpkgs)
- System and user configurations are built separately for better isolation
- Neovim is configured with lazy-nvim and comprehensive treesitter grammar support
- macOS system defaults are configured for development efficiency (faster key repeat, show file extensions, dock autohide)