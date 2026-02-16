# ~/dotfiles/flake.nix
{
  description = "A clean macOS nix-darwin + home-manager configuration";

  inputs = {
    # Use the latest stable Nixpkgs branch (adjust if needed, e.g., nixos-unstable)
    # As of May 2025, 24.05 is the latest stable.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Use the corresponding nix-darwin branch/tag
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs"; # Ensures darwin uses the same nixpkgs

    # Use the corresponding home-manager branch/tag
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # Ensures home-manager uses the same nixpkgs
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
  let
    # --- !!! EDIT THESE VARIABLES !!! ---w
    # Set to your macOS username
    username = "swe"; # <--- REPLACE 'swe' with your actual username

    # Set to your system architecture
    # Use "aarch64-darwin" for Apple Silicon (M1, M2, M3...)
    # Use "x86_64-darwin" for Intel Macs
    #system = "x86_64-darwin"; # <--- SET CORRECT ARCHITECTURE
    system = "aarch64-darwin"; # <--- SET CORRECT ARCHITECTURE
    # --- !!! END OF EDITABLE VARIABLES !!! ---

    # Helper for home directory path
    homeDirectory = "/Users/${username}";

    # Overlay: disable failing setproctitle tests on macOS (segfault in fork tests)
    setproctitleOverlay = final: prev: {
      python313 = prev.python313.override {
        packageOverrides = pfinal: pprev: {
          setproctitle = pprev.setproctitle.overrideAttrs { doInstallCheck = false; };
        };
      };
    };

    # Standard Nixpkgs instance for the specified system
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      overlays = [ setproctitleOverlay ];
    };

    # Nix-darwin library functions
    lib = darwin.lib;
  in
  {
    # === nix-darwin System Configuration ===
    # Defines the main system configuration build
    darwinConfigurations."${username}" = lib.darwinSystem {
      inherit system;

      # Pass inputs, pkgs, and other useful values down to the modules
      specialArgs = { inherit inputs pkgs username homeDirectory; };

      # List of modules to include in the system configuration
      modules = [
        # Import the main system configuration settings
        ./darwin-configuration.nix

        # home-manager is now managed independently via 'home-manager switch'
        # home-manager.darwinModules.home-manager,
        # {
        #   home-manager.useGlobalPkgs = true;
        #   home-manager.useUserPackages = true;
        #   home-manager.extraSpecialArgs = { inherit pkgs username homeDirectory; };
        #   home-manager.users.${username} = import ./home.nix;
        #   #home.stateVersion = "25.05";
        # }
      ];
    };

    homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "${system}"; overlays = [ setproctitleOverlay ]; };
      # Pass system-level specialArgs plus any others needed by home.nix modules
      extraSpecialArgs = { inherit inputs pkgs username homeDirectory; }; 
      modules = [
        ./home.nix
        # You could add other home-manager specific modules here if needed
      ];
    };

    # --- Build & Activation Instructions ---
    # For system changes (darwin-configuration.nix):
    # 1. nix build '.#darwinConfigurations.swe.system'
    # 2. sudo ./result/bin/darwin-rebuild switch
    #
    # For user environment changes (home.nix):
    # 1. home-manager switch --flake .#swe
    #

    # NOTE: The 'apps' block for 'nix run .#rebuild' is intentionally omitted
    #       to avoid the previous evaluation issues.

    # To build and activate your system configuration:
    # 1. Navigate to this flake's directory (e.g., ~/dotfiles) in your terminal.
    # 2. Build the configuration:
    #    nix build '.#darwinConfigurations.<username>.system' --print-build-logs
    #    (Replace <username> with your actual macOS username, keep the quotes)
    # 3. Activate the built configuration:
    #    sudo ./result/bin/darwin-rebuild switch
    #    (The './result' symlink is created by the 'nix build' command)

  };
}
