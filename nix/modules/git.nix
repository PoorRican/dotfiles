# Git version control
{ pkgs, ... }:
{
  home.packages = with pkgs; [ git git-lfs gh ];
  xdg.configFile."git/config".source = ../../git/config;
  xdg.configFile."git/ignore".source = ../../git/ignore;
}
