# OpenAI Codex CLI — installation only (installed outside Nix)
# Disables the built-in home-manager module in favor of external install.
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.codex;
  bun = "${pkgs.bun}/bin/bun";
in {
  disabledModules = [ "programs/codex.nix" ];

  options.programs.codex = {
    enable = lib.mkEnableOption "codex";
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run `bun install -g @openai/codex` on every home-manager switch.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.installCodex =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! command -v codex &> /dev/null; then
          run ${bun} install -g @openai/codex
        ${lib.optionalString cfg.autoUpdate ''
        else
          run ${bun} install -g @openai/codex
        ''}
        fi
      '';
  };
}
