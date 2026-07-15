# Neovim — binary + language providers from nix. All plugins and configuration
# are managed by the user's lazy.nvim setup under configs/neovim.
#
# We deliberately do NOT use home-manager's `programs.neovim`: in release-26.05
# it emits ~/.config/nvim/init.lua (to set the provider *_host_prog vars), which
# collides with the whole-directory symlink below and fails the build with
# "Error installing file '.config/nvim/init.lua' outside $HOME". The plain
# `pkgs.neovim` wrapper instead injects the host_prog vars via `--cmd`, so the
# user's own init.lua still loads. (The lua config also sets
# `performance.reset_packpath = true`, which discards nix-provided plugins at
# runtime anyway, so the old `programs.neovim.plugins` block was dead weight.)
{ pkgs, config, ... }:
{
  # Live, out-of-store symlink to the working tree. The lua config relies on
  # stdpath('config') resolving here (lazy lockfile, linter-configs/, db_ui, …),
  # so it must be the whole dir. The target MUST be a real filesystem path — NOT
  # the flake's `dotfiles` store snapshot (./.), which nix-collect-garbage
  # deletes, leaving ~/.config/nvim dangling. That was the original breakage.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/neovim";

  home.packages = [
    (pkgs.neovim.override {
      withRuby = true;
      withPython3 = true;
      withPerl = true;
      withNodeJs = false;
    })
    pkgs.markdown-oxide
    pkgs.nixd
    pkgs.nixfmt
    pkgs.tree-sitter
  ];
}
