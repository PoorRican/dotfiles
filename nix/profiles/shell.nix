# Terminal emulators, multiplexers, fonts, shell
{ pkgs, ... }:
{# TODO: setup configurations
  home.packages = with pkgs; [
    tmux
    zellij
    oh-my-zsh
    jetbrains-mono
  ];
}
