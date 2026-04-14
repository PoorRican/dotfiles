# Dotfiles

This dotfiles repository is managed with [Nix Flakes](https://nixos.wiki/wiki/Flakes) using nix-darwin and home-manager for package management across macOS and Linux. Configurations live under `configs/` and are deployed via home-manager modules.

## Building and Activating

### User environment (home-manager)

```bash
home-manager switch --flake .#mbp      # macOS
home-manager switch --flake .#dgx      # DGX (Linux)
home-manager switch --flake .#emc      # Linux server
```

If `home-manager` is not installed yet, bootstrap it with:

```bash
./bin/bin/bootstrap-dotfiles
nix run home-manager/release-25.11 -- switch --flake .#emc
```

### System configuration (macOS only)

```bash
nix build '.#darwinConfigurations.swe.system' --print-build-logs
sudo ./result/bin/darwin-rebuild switch
```

## Updating Flake Inputs

Update a specific input (e.g., hermes-agent):

```bash
nix flake update hermes-agent
```

Then rebuild your configuration:

```bash
home-manager switch --flake .#<host>
```

## Repository Layout

```
configs/          App configurations (ghostty, git, helix, neovim, tmux, zellij, zsh)
assets/           Static resources (banners, figlet fonts, imported fonts)
bin/              Custom scripts
claude/           Claude Code configuration
nix/              Nix infrastructure (hosts, modules, profiles, layers)
docs/             Documentation
```

## Adding a New Config

1. Create a directory under `configs/` with the target XDG structure
2. Create `nix/modules/<name>.nix` using `{ dotfiles, ... }:` to receive the repo root
3. Reference config files with `dotfiles + "/configs/<name>/..."`
4. Import the module from the appropriate host config in `nix/hosts/`
5. Rebuild: `home-manager switch --flake .#mbp`

See `CLAUDE.md` for Nix architecture details and gotchas.
