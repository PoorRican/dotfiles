# ~/dotfiles/flake.nix
{
  description = "shared and universal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, home-manager, hermes-agent, ... }@inputs:
  let
    # nixpkgs 26.05 currently ships Bun 1.3.13, but OMP's npm package
    # requires Bun 1.3.14+. Keep this as a tiny overlay instead of moving the
    # whole flake forward and changing unrelated inputs in flake.lock.
    bun_1_3_14_overlay = final: prev: {
      bun = prev.bun.overrideAttrs (final_attrs: previous_attrs: {
        version = "1.3.14";
        src =
          final_attrs.passthru.sources.${prev.stdenvNoCC.hostPlatform.system}
            or (throw "Unsupported system: ${prev.stdenvNoCC.hostPlatform.system}");
        passthru = previous_attrs.passthru // {
          sources = {
            "aarch64-darwin" = final.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v${final_attrs.version}/bun-darwin-aarch64.zip";
              hash = "sha256-2LliIYKK1vl6x6wKt+lYcjQa92MAHogD6CZ2UsJlJiA=";
            };
            "aarch64-linux" = final.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v${final_attrs.version}/bun-linux-aarch64.zip";
              hash = "sha256-on/7Y6gxA3WDbg1vZorhf6jY0YuIw3yCHGUzGXOhmjs=";
            };
            "x86_64-darwin" = final.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v${final_attrs.version}/bun-darwin-x64-baseline.zip";
              hash = "sha256-PjWtb1OXGpg0v55nhuKt9ytfGSHMmpxf3gc9KXKUQHY=";
            };
            "x86_64-linux" = final.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v${final_attrs.version}/bun-linux-x64.zip";
              hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
            };
          };
        };
      });
    };

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
          # Apply the Bun pin to every host so shared dev tooling evaluates the
          # same way on Linux and Darwin; host-specific overlays still append.
          overlays = [ bun_1_3_14_overlay ] ++ overlays;
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
        overlays = [ darwinTestFixesOverlay ];
        modules = [
          ./nix/hosts/mbp.nix
        ];
      };
      dgx = mkHome {
        system = "aarch64-linux";
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
      cbox = mkHome {
        system = "x86_64-linux";
        username = "swe";
        homeDirectory = "/home/swe";
        modules = [ ./nix/hosts/cbox.nix ];
      };
    };
  };
}
