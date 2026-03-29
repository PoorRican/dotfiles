# Terminal emulators, multiplexers, fonts, shell
{ pkgs, ... }:
{
  imports = [
    ../modules/tmux.nix
    ../modules/zellij.nix
    ../modules/zsh.nix
  ];

  home.packages = with pkgs; [
    jetbrains-mono
  ];
}
