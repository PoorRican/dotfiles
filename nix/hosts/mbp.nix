# macOS (MacBook Pro) host-specific settings
{ pkgs, config, lib, dotfiles, ... }:
{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/dev-core.nix
    ../profiles/dev-cloud.nix
    ../profiles/dev-extra.nix
		#../profiles/server.nix
    ../modules/ghostty.nix
		../modules/taskwarrior.nix
  ];

  programs.hermes.profiles.default = {
    settings = {
      # macOS keeps the Apple skills that the portable policy hides.
      skills.disabled = lib.mkForce (lib.remove "apple"
        (import (dotfiles + "/configs/hermes/default/config.nix") { }).skills.disabled);
      mcp_servers = {
        motion.command = "${config.programs.hermes.profiles.default.home}/bin/motion-mcp-hermes";
        rescuetime.command = "${config.programs.hermes.profiles.default.home}/bin/rescuetime-mcp-hermes";
      };
    };
    files = {
      "bin/motion-mcp-hermes" = dotfiles + "/configs/hermes/mbp/motion-mcp-hermes";
      "bin/rescuetime-mcp-hermes" = dotfiles + "/configs/hermes/mbp/rescuetime-mcp-hermes";
    };
  };
  programs.agent-skills.host = "mbp";
  programs.claude-code.autoUpdate = true;

  home.packages = with pkgs; [
    iterm2

    # dev - misc
    nmap
    ruby
    firebase-tools

    # dev - image tools
    cairo
    cairosvg
    graphviz
  ];

  home.sessionVariables = {
    DYLD_FALLBACK_LIBRARY_PATH = "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager/home-path/lib";
  };

  targets.darwin.copyApps.enableChecks = false;
}
