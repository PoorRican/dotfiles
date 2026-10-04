# Git version control
{ config, lib, dotfiles, pkgs, ... }:
{
  # Private modules (such as the agent-profiles input) add global ignore
  # patterns here instead of publishing them in configs/git/ignore.
  options.my.git.extraIgnores = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Patterns appended to the global gitignore after configs/git/ignore.";
  };

  config = {
    home.packages = with pkgs; [ git git-lfs gh ];
    xdg.configFile."git/config".source = dotfiles + "/configs/git/config";
    xdg.configFile."git/ignore".text =
      builtins.readFile (dotfiles + "/configs/git/ignore")
      + lib.concatMapStrings (pattern: "${pattern}\n") config.my.git.extraIgnores;
  };
}
