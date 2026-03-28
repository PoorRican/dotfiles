# Neovim program configuration (plugins, treesitter parsers)
{ pkgs, config, ... }:
{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/neovim";

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      lazy-nvim
      nvim-lspconfig
      nvim-treesitter-textobjects
      (nvim-treesitter.withPlugins (parsers: with parsers; [
        tree-sitter-bash
        tree-sitter-c
        tree-sitter-cpp
        tree-sitter-css
        tree-sitter-go
        tree-sitter-html
        tree-sitter-javascript
        tree-sitter-json
        tree-sitter-lua
        tree-sitter-nix
        tree-sitter-python
        tree-sitter-rust
        tree-sitter-ssh_config
        tree-sitter-sql
        tree-sitter-toml
        tree-sitter-tmux
        tree-sitter-tsx
        tree-sitter-typescript
        tree-sitter-xml
        tree-sitter-cmake
        tree-sitter-csv
        tree-sitter-yaml
        tree-sitter-gitcommit
      ]))
    ];
  };
}
