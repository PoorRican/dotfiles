# ~/dotfiles/home.nix
# Defines user-specific settings managed by Home Manager

{ config, pkgs, lib, username, homeDirectory, ... }:

{
  # Home Manager state version (use string format, match nixpkgs branch)
  # !! IMPORTANT: Update this if you change nixpkgs branch !!
  home.stateVersion = "25.05";

  # Basic user info
  home.username = "${username}";
  home.homeDirectory = "${homeDirectory}";

  # Packages specifically for this user (includes GUI apps, user tools)
  home.packages = with pkgs; [
    # Dev tools
    # go
    nodejs_22
    bun
    google-cloud-sdk
    pulumi
    pulumiPackages.pulumi-python
    pulumiPackages.pulumi-nodejs
    awscli2
    cargo
    git-lfs
    luarocks
    sqlite
    helix

    # CLI tools
    ripgrep # Fast grep alternative
    fd # Fast find alternative
    bat # Cat alternative with syntax highlighting
    jq # JSON processor
    gh # GitHub CLI
    stow
    tmux
    oh-my-zsh
    yazi
    nmap
    
    # LSP servers
    pyright # Python LSP server

    # Fonts
    jetbrains-mono

    # GUI Apps (managed via homebrew casks if needed, see home-manager docs)
    kitty
    iterm2
    # firefox
    # visual-studio-code
  ];

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      lazy-nvim
      nvim-lspconfig
      nvim-treesitter-textobjects # For better text objects based on treesitter
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
        tree-sitter-csv
        tree-sitter-tmux
        tree-sitter-yaml
      ]))
      (nvim-treesitter.withPlugins (grammars: with grammars; [
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
        tree-sitter-csv
        tree-sitter-tmux
        tree-sitter-yaml
      ]))
    ];
  };

  # Git configuration
  #programs.git = {
  #  enable = true;
  #};

  # Example: Zsh configuration (customize as needed)
  # programs.zsh = {
  #   enable = true;
  #   enableAutosuggestions = true;
  #   enableCompletion = true;
  #   syntaxHighlighting.enable = true;
  #   oh-my-zsh = {
  #     enable = true;
  #     plugins = [ "git" "sudo" ]; # Add desired plugins
  #     theme = "robbyrussell";   # Choose your theme
  #   };
  # };

  # Example: Set environment variables for the user session
  # home.sessionVariables = {
  #   EDITOR = "vim";
  # };

  # Enable Home Manager itself (required)
  programs.home-manager.enable = true;
}
