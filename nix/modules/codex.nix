# OpenAI Codex CLI — installation only (installed outside Nix)
# Disables the built-in home-manager module in favor of external install.
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.codex;
  bun = "${pkgs.bun}/bin/bun";
  ext = import ./lib/mk-external-install.nix { inherit lib pkgs; } {
    name = "codex";
    binary = "codex";
    installCmd = "${bun} install -g @openai/codex";
    updateCmd = "${bun} install -g @openai/codex";
  };
in {
  disabledModules = [ "programs/codex.nix" ];

  options.programs.codex = ext.options;

  config = lib.mkIf cfg.enable {
    home.activation.installCodex = ext.mkActivation cfg;
  };
}
