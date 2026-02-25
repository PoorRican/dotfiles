# Terminal emulators, multiplexers, fonts, shell
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kitty
    iterm2
    tmux
    zellij
    oh-my-zsh
    helix
    jetbrains-mono
  ];
}
