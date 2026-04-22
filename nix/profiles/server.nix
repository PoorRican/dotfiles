{ pkgs, ... }:
{
  home.packages = with pkgs; [
    #proton-pass-cli
    mosh
  ];
}
