# Terminal emulators, multiplexers, fonts, shell
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kitty
    tmux
    zellij
    oh-my-zsh
    helix
    jetbrains-mono
  ];
}
