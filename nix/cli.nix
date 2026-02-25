# General-purpose CLI utilities
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    jq
    fzf
    tree
    yazi
    nmap
    coreutils-full
    rclone
    mosh
    stow
    graphviz
  ];
}
