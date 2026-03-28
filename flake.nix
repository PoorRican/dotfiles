# ~/dotfiles/flake.nix
{
  description = "shared and universal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    setproctitleOverlay = final: prev: {
      python313 = prev.python313.override {
        packageOverrides = pfinal: pprev: {
          setproctitle = pprev.setproctitle.overrideAttrs { doInstallCheck = false; };
        };
      };
    };

    mkHome = { system, username, homeDirectory, modules, overlays ? [] }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          inherit overlays;
        };
        modules = modules ++ [
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
            home.stateVersion = "25.11";
            programs.home-manager.enable = true;
          }
        ];
      };
  in
  {
    homeConfigurations = {
      mbp = mkHome {
        system = "aarch64-darwin";
        username = "swe";
        homeDirectory = "/Users/swe";
        overlays = [ setproctitleOverlay ];
        modules = [
          ./nix/cli.nix
          ./nix/cloud.nix
          ./nix/dev-tools.nix
          ./nix/languages.nix
          ./nix/ricing.nix
          ./nix/neovim.nix
          ./nix/hosts/mbp.nix
        ];
      };
    };
  };
}
