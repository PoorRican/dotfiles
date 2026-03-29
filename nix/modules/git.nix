# Git version control
{ dotfiles, pkgs, ... }:
{
  home.packages = with pkgs; [ git git-lfs gh ];
  xdg.configFile."git/config".source = dotfiles + "/configs/git/config";
  xdg.configFile."git/ignore".source = dotfiles + "/configs/git/ignore";
}
