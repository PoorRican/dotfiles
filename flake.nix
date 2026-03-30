# ~/dotfiles/flake.nix
{
  description = "shared and universal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    imsg-overlay = {
      url = "github:PoorRican/imsg-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, home-manager, imsg-overlay, ... }:
  let
    setproctitleOverlay = final: prev: {
      python313 = prev.python313.override {
        packageOverrides = pfinal: pprev: {
          setproctitle = pprev.setproctitle.overrideAttrs { doInstallCheck = false; };
        };
      };
    };

    hermes = import ./nix/modules/hermes.nix;

    mkHome = { system, username, homeDirectory, modules, overlays ? [] }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          inherit overlays;
        };
        extraSpecialArgs = { dotfiles = ./.; };
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
        overlays = [ setproctitleOverlay imsg-overlay.overlays.default ];
        modules = [
          hermes.default
          ./nix/hosts/mbp.nix
        ];
      };
      dgx = mkHome {
        system = "x86_64-linux";
        username = "sparky";
        homeDirectory = "/home/sparky";
        modules = [
          hermes.default
          ./nix/hosts/dgx.nix
        ];
      };
      server = mkHome {
        system = "x86_64-linux";
        username = "swe";
        homeDirectory = "/home/swe";
        modules = [ ./nix/hosts/server.nix ];
      };
    };
  };
}
