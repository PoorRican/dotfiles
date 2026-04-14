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
      url = "path:/Users/swe/repos/imsg-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, home-manager, imsg-overlay, hermes-agent, ... }@inputs:
  let
    darwinTestFixesOverlay = final: prev: {
      python313 = prev.python313.override {
        packageOverrides = pfinal: pprev: {
          setproctitle = pprev.setproctitle.overrideAttrs { doInstallCheck = false; };
        };
      };
      direnv = prev.direnv.overrideAttrs { doCheck = false; };
      # Pin jetbrains-mono to use pre-built fonts from repo, avoiding gftools → ffmpeg-python bloat
      jetbrains-mono = prev.jetbrains-mono.overrideAttrs {
        nativeBuildInputs = [ ];
        buildPhase = "true";
      };
    };

    mkHome = { system, username, homeDirectory, modules, overlays ? [] }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          inherit overlays;
        };
        extraSpecialArgs = {
          dotfiles = ./.;
          inherit inputs;
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
        overlays = [ darwinTestFixesOverlay imsg-overlay.overlays.default ];
        modules = [
          ./nix/hosts/mbp.nix
        ];
      };
      dgx = mkHome {
        system = "x86_64-linux";
        username = "sparky";
        homeDirectory = "/home/sparky";
        modules = [
          ./nix/hosts/dgx.nix
        ];
      };
      emc = mkHome {
        system = "x86_64-linux";
        username = "swe";
        homeDirectory = "/home/swe";
        modules = [ ./nix/hosts/emc.nix ];
      };
    };
  };
}
