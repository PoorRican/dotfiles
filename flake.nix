# ~/dotfiles/flake.nix
{
  description = "A clean macOS nix-darwin + home-manager configuration";

  inputs = {
    # Use the latest stable Nixpkgs branch (adjust if needed, e.g., nixos-unstable)
    # As of May 2025, 24.05 is the latest stable.
    nixpkgs.url = "github:NixOS/nixpkgs";

    # Use the corresponding nix-darwin branch/tag
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs"; # Ensures darwin uses the same nixpkgs

    # Use the corresponding home-manager branch/tag
    home-manager.url = "github:nix-community/home-manager";
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
    system = "x86_64-darwin"; # <--- SET CORRECT ARCHITECTURE
    # --- !!! END OF EDITABLE VARIABLES !!! ---

    # Helper for home directory path
    homeDirectory = "/Users/${username}";

    # Standard Nixpkgs instance for the specified system
    # You can add overlays or configuration options here if needed
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; }; # Example: Allow unfree packages
      # overlays = [ ]; # Add overlays if you have any
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

        # Import the home-manager module for nix-darwin integration
        home-manager.darwinModules.home-manager
        {
          # Configure home-manager settings here at the system level
          home-manager.useGlobalPkgs = true; # Let HM use the pkgs defined above
          home-manager.useUserPackages = true; # Let HM manage packages defined in home.nix
          home-manager.extraSpecialArgs = { inherit pkgs username homeDirectory; }; # Pass args to HM's modules

          # Tell home-manager which user(s) to manage and where their config is
          home-manager.users.${username} = import ./home.nix;

          # Set the state version for home-manager itself. Match nixpkgs branch.
          # !! IMPORTANT: Update this if you change nixpkgs branch !!
          #home.stateVersion = "25.05"; # Use the string format here
        }
      ];
    };

    # --- Build & Activation Instructions ---
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
