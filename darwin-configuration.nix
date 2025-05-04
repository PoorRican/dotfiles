# ~/dotfiles/darwin-configuration.nix
# Defines system-wide settings managed by nix-darwin

{ config, pkgs, lib, username, homeDirectory, ... }:

{
  # Required: Set nix-darwin's state version. Must be an integer.
  # Increment this when making potentially breaking changes.
  system.stateVersion = 6; # Use an integer (e.g., 4 or 5)

  # List packages to install system-wide (mostly command-line tools)
  # User applications (especially GUI) are better managed in home.nix
  environment.systemPackages = with pkgs; [
    git # Smaller git package, use 'git' if you need full features
    wget
    curl
    neovim
    htop # Example process viewer
    coreutils # Provides GNU core utilities (like gls)
  ];

  # Configure Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Allow members of the admin group (standard macOS admins) to use sudo with Nix
    trusted-users = [ "root" "@admin" ];
  };
  # Optional: Configure automatic garbage collection
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d"; # Keep builds for 7 days
  };

  # Configure shell integration (ensure Zsh is set up correctly)
  programs.zsh.enable = true;
  # programs.bash.enable = true; # Uncomment if you use Bash

  # Define the main user account managed by nix-darwin
  users.users.${username} = {
    name = username;
    home = homeDirectory;
    # shell = pkgs.zsh; # You can explicitly set the shell if desired
  };

  # Example system-wide preferences (more available, see nix-darwin options)
  system.defaults = {
    finder.AppleShowAllExtensions = true; # Show all file extensions
    dock.autohide = true; # Autohide the Dock
    NSGlobalDomain.InitialKeyRepeat = 15; # Faster key repeat rate
    NSGlobalDomain.KeyRepeat = 2;       # Faster key repeat rate
  };

  # Enable Touch ID for sudo authentication (requires PAM module)
  # security.pam.enableSudoTouchIdAuth = true;

  # Add any other system-wide configurations here
  # services.nix-daemon.enable = true; # Often enabled by default now

}
