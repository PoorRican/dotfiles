# Oh My Pi coding agent — installation only (installed outside Nix)
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.omp;
  # OMP is published as an npm package. Use Home Manager activation to install
  # it with the flake-pinned Bun rather than packaging a separate derivation.
  bun = "${pkgs.bun}/bin/bun";
  ext = import ./lib/mk-external-install.nix { inherit lib pkgs; } {
    name = "omp";
    binary = "omp";
    installCmd = "${bun} install -g @oh-my-pi/pi-coding-agent";
    updateCmd = "${bun} install -g @oh-my-pi/pi-coding-agent";
  };
in {
  options.programs.omp = ext.options;

  config = lib.mkIf cfg.enable {
    home.activation.installOmp = ext.mkActivation cfg;
  };
}
