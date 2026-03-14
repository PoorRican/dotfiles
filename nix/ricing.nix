# Terminal emulators, multiplexers, fonts, shell
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    kitty
    tmux
    zellij
    oh-my-zsh
    helix
    jetbrains-mono
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    iterm2
  ];
}
