# ~/dotfiles/home.nix
# Thin hub — actual packages live in nix/*.nix modules

{ config, pkgs, lib, username, homeDirectory, ... }:
{
  imports = [
    ./nix/languages.nix
    ./nix/cloud.nix
    ./nix/dev-tools.nix
    ./nix/cli.nix
    ./nix/ricing.nix
    ./nix/neovim.nix
  ];

  home.stateVersion = "25.11";
  home.username = "${username}";
  home.homeDirectory = "${homeDirectory}";

  home.sessionVariables = {
    DYLD_FALLBACK_LIBRARY_PATH = "${homeDirectory}/.local/state/nix/profiles/home-manager/home-path/lib";
  };

  programs.home-manager.enable = true;
  targets.darwin.copyApps.enableChecks = false;
}
