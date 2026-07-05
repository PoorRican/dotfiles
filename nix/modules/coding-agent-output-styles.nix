# Claude-style output prompts for Pi and Oh My Pi.
#
# The agents load extension files from ~/.pi/agent/extensions and
# ~/.omp/agent/extensions. Keep the extension and prompt text in dotfiles, then
# expose them as out-of-store symlinks so slash-command edits remain live.
{ config, lib, ... }:
let
  cfg = config.programs.coding-agent-output-styles;
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";

  mkAgentFiles = targetRoot: sourceRoot: {
    "${targetRoot}/extensions/claude-output-styles.ts" = {
      source = config.lib.file.mkOutOfStoreSymlink "${sourceRoot}/extensions/claude-output-styles.ts";
      force = true;
    };
    "${targetRoot}/output-styles/explanatory.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${sourceRoot}/output-styles/explanatory.md";
      force = true;
    };
    "${targetRoot}/output-styles/learning.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${sourceRoot}/output-styles/learning.md";
      force = true;
    };
    "${targetRoot}/output-style.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${sourceRoot}/output-style.json";
      force = true;
    };
  };
in {
  options.programs.coding-agent-output-styles = {
    enable = lib.mkEnableOption "Claude-style output prompt toggles for Pi and OMP";

    enablePi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Manage the Pi (~/.pi/agent) output-style extension and prompts.";
    };

    enableOmp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Manage the OMP (~/.omp/agent) output-style extension and prompts.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge [
      (lib.mkIf cfg.enablePi (mkAgentFiles ".pi/agent" "${dotfilesPath}/configs/pi/agent"))
      (lib.mkIf cfg.enableOmp (mkAgentFiles ".omp/agent" "${dotfilesPath}/configs/omp/agent"))
    ];
  };
}
