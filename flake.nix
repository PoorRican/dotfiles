# ~/dotfiles/flake.nix
{
  description = "shared and universal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    darwin = {
			url = "github:LnL7/nix-darwin";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		home-manager = {
			url = "github:nix-community/home-manager/release-25.11";
    	inputs.nixpkgs.follows = "nixpkgs";
		};

		imsg-overlay = {
			url = "github:PoorRican/imsg-overlay";
    	inputs.nixpkgs.follows = "nixpkgs";
		};
  };

  outputs = { self, nixpkgs, darwin, home-manager, imsg-overlay, ... }@inputs:
  let
    username = "swe";
    darwinSystem = "aarch64-darwin";
    linuxSystem = "x86_64-linux";
    darwinHomeDirectory = "/Users/${username}";
    linuxHomeDirectory = "/home/${username}";

    setproctitleOverlay = final: prev: {
      python313 = prev.python313.override {
        packageOverrides = pfinal: pprev: {
          setproctitle = pprev.setproctitle.overrideAttrs { doInstallCheck = false; };
        };
      };
    };

    mkPkgs = system: import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      overlays = [
        setproctitleOverlay
      ] ++ nixpkgs.lib.optionals (nixpkgs.lib.hasSuffix "-darwin" system) [
        imsg-overlay.overlays.default
      ];
    };

    mkHome = { system, homeDirectory }:
      let
        pkgs = mkPkgs system;
      in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs pkgs username homeDirectory; };
        modules = [ ./home.nix ];
      };

    darwinPkgs = mkPkgs darwinSystem;
  in
  {
    darwinConfigurations."${username}" = darwin.lib.darwinSystem {
      system = darwinSystem;
      specialArgs = {
        inherit inputs username;
        pkgs = darwinPkgs;
        homeDirectory = darwinHomeDirectory;
      };
      modules = [ ./darwin-configuration.nix ];
    };

    homeConfigurations."${username}" = mkHome {
      system = darwinSystem;
      homeDirectory = darwinHomeDirectory;
    };

    homeConfigurations."${username}-linux" = mkHome {
      system = linuxSystem;
      homeDirectory = linuxHomeDirectory;
    };
  };
}
