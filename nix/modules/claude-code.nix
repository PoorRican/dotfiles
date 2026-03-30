# Claude Code — config + installation (installed outside Nix)
# Disables the built-in home-manager module (which copies to nix store)
# in favor of mkOutOfStoreSymlink for live editing from dotfiles.
{ config, lib, ... }:
let
  cfg = config.programs.claude-code;
  dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/claude-code";
in {
  disabledModules = [ "programs/claude-code.nix" ];

  options.programs.claude-code = {
    enable = lib.mkEnableOption "claude-code";
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run `claude update` on every home-manager switch.";
    };
  };

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

    home.activation.installClaudeCode =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! command -v claude &> /dev/null; then
          run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
        ${lib.optionalString cfg.autoUpdate ''
        else
          run claude update
        ''}
        fi
      '';
  };
}
