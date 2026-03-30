# Claude Code — config only (installed outside Nix)
{ config, ... }:
let
  dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/claude-code";
in {
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
}
