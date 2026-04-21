# Pulumi CLI — external install via official installer to keep bundled YAML runtime working.
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pulumi;
  version = "3.231.0";
  ext = import ./lib/mk-external-install.nix { inherit lib pkgs; } {
    name = "pulumi";
    binary = "pulumi";
    installCmd = "curl -fsSL https://get.pulumi.com | bash -s -- --version ${version} --install-root \"$HOME/.local\" --no-edit-path";
    updateCmd = "curl -fsSL https://get.pulumi.com | bash -s -- --version ${version} --install-root \"$HOME/.local\" --no-edit-path";
    useCurl = true;
  };
in {
  options.programs.pulumi = ext.options;

  config = lib.mkIf cfg.enable {
    home.activation.installPulumi = ext.mkActivation cfg;
  };
}
