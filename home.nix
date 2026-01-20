# ~/dotfiles/home.nix
# Defines user-specific settings managed by Home Manager

{ config, pkgs, lib, username, homeDirectory, ... }:

{
  # Home Manager state version (use string format, match nixpkgs branch)
  # !! IMPORTANT: Update this if you change nixpkgs branch !!
  home.stateVersion = "25.11";

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
    git-lfs
    luarocks
    sqlite
    helix
    postgresql_17_jit
    tree
    mosh
    graphviz
    rclone
    firebase-tools
    cairo
    cairosvg
    zellij
		fzf

    # rust toolchain
    rustup

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
        tree-sitter-yaml
        tree-sitter-gitcommit
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

  # Set environment variables for the user session
  home.sessionVariables = {
    # Make Nix-installed libraries discoverable by Python packages like cairocffi
    DYLD_FALLBACK_LIBRARY_PATH = "${homeDirectory}/.local/state/nix/profiles/home-manager/home-path/lib";
  };

  # Enable Home Manager itself (required)
  programs.home-manager.enable = true;

  # Disable App Management preflight check for copying apps
  targets.darwin.copyApps.enableChecks = false;
}
