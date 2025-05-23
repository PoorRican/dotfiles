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
    # nodejs_20 # Example specific version
    bun


    # CLI tools
    ripgrep # Fast grep alternative
    fd # Fast find alternative
    bat # Cat alternative with syntax highlighting
    jq # JSON processor
    gh # GitHub CLI
    stow
    neovim
    tmux
    oh-my-zsh

    # Fonts
    jetbrains-mono

    # GUI Apps (managed via homebrew casks if needed, see home-manager docs)
    kitty
    iterm2
    # firefox
    # visual-studio-code
  ];

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
