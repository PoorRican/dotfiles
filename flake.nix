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

    hermes-agent = {
      url = "github:nousresearch/hermes-agent";
      # No follows — its uv2nix build targets nixos-24.11
    };
  };

  outputs = { nixpkgs, home-manager, imsg-overlay, hermes-agent, ... }:
  let
    setproctitleOverlay = final: prev: {
      python313 = prev.python313.override {
        packageOverrides = pfinal: pprev: {
          setproctitle = pprev.setproctitle.overrideAttrs { doInstallCheck = false; };
        };
      };
    };

    hermesAgentOverlay = final: prev: {
      hermes-agent = hermes-agent.packages.${final.system}.default;
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
        overlays = [ setproctitleOverlay hermesAgentOverlay imsg-overlay.overlays.default ];
        modules = [
					./nix/profiles/dev-cloud.nix
					./nix/profiles/dev-extra.nix
					./nix/profiles/dev-core.nix
					./nix/profiles/minimal.nix
					./nix/profiles/shell.nix
          ./nix/modules/hermes.nix
					./nix/modules/neovim.nix
          ./nix/hosts/mbp.nix
        ];
      };
    };
  };
}
