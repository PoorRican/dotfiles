# Emergency CA bundle for standalone Nix profiles (Arch/Ubuntu, not NixOS).
# Uses this repository's locked nixpkgs without updating unrelated packages.
# Build: nix build --impure --file nix/security-cacert.nix --no-link
# Install into the installer-owned default profile with higher priority than
# its existing cacert package; verify the active bundle before removing the old
# profile entry. Never edit certificate files inside /nix/store.
let
  flake = builtins.getFlake (toString ../.);
  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
  };
in
pkgs.cacert.override {
  # Same mitigation as nixos/modules/security/ca.nix for CVE-2026-111943.
  blacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];
}
