# Claude Code — config + installation (installed outside Nix)
# Disables the built-in home-manager module (which copies to nix store)
# in favor of mkOutOfStoreSymlink for live editing from dotfiles.
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.claude-code;
  dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/claude-code";
  ext = import ./lib/mk-external-install.nix { inherit lib pkgs; } {
    name = "claude-code";
    binary = "claude";
    installCmd = "curl -fsSL https://claude.ai/install.sh | bash";
    updateCmd = "claude update";
    useCurl = true;
  };
in {
  disabledModules = [ "programs/claude-code.nix" ];

  options.programs.claude-code = ext.options;

  config = lib.mkIf cfg.enable {
    home.file.".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/settings.json";
    home.file.".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/CLAUDE.md";
    home.file.".claude/agents".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/agents";
    home.file.".claude/commands".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/commands";
    home.file.".claude/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/skills";

    home.activation.installClaudeCode = ext.mkActivation cfg;
  };
}
