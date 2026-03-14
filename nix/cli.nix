# General-purpose CLI utilities
{ pkgs, lib, ... }:
{
  home.packages =
    (with pkgs; [
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
    ])
    ++ lib.optionals pkgs.stdenv.isDarwin [
      pkgs.imsg
    ];
}
