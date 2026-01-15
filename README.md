# Dotfiles

This dotfiles repository is managed using [GNU Stow](https://www.gnu.org/software/stow/) for symlinking and [Nix Flakes](https://nixos.wiki/wiki/Flakes) with nix-darwin and home-manager for package management.

## Managing Symlinks with Stow

Each top-level directory (e.g., `zsh/`, `nvim/`, `tmux/`) is a stow package. Stow creates symlinks from these directories into your home directory.

### Stow a Package

To symlink a package to your home directory:

```bash
cd ~/dotfiles
stow <package>
```

For example, to stow the zsh configuration:

```bash
stow zsh
```

### Unstow a Package

To remove symlinks for a specific package:

```bash
cd ~/dotfiles
stow -D <package>
```

For example, to unstow the claude configuration:

```bash
stow -D claude
```

### Available Packages

| Package | Description |
|---------|-------------|
| `banners` | Custom banner files |
| `bin` | User scripts |
| `claude` | Claude Code configuration |
| `figlet` | Figlet fonts |
| `git` | Git configuration |
| `helix` | Helix editor configuration |
| `ngrok` | Ngrok configuration |
| `nvim` | Neovim configuration |
| `tmux` | Tmux configuration |
| `zsh` | Zsh shell configuration |

### Useful Flags

- `-n, --no`: Dry run - show what would be done without making changes
- `-v, --verbose`: Increase verbosity
- `-D, --delete`: Unstow (remove symlinks)
- `-R, --restow`: Restow (useful after modifying packages)

Example dry run:

```bash
stow -nv zsh
```

## Nix Configuration

See CLAUDE.md for Nix build commands and architecture details.
