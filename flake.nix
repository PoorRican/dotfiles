# ~/dotfiles/flake.nix
{
  description = "macOS nix-darwin + home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
  let
    username = "swe";
    system = "aarch64-darwin";
    homeDirectory = "/Users/${username}";

    setproctitleOverlay = final: prev: {
      python313 = prev.python313.override {
        packageOverrides = pfinal: pprev: {
          setproctitle = pprev.setproctitle.overrideAttrs { doInstallCheck = false; };
        };
      };
    };

    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      overlays = [ setproctitleOverlay ];
    };
  in
  {
    darwinConfigurations."${username}" = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs pkgs username homeDirectory; };
      modules = [ ./darwin-configuration.nix ];
    };

    homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs pkgs username homeDirectory; };
      modules = [ ./home.nix ];
    };
  };
}
