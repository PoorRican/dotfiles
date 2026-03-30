# DGX GPU server host-specific settings
{ pkgs, ... }:
{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/dev-core.nix
		../profiles/dev-extra.nix
  ];

  home.packages = with pkgs; [
  ];
}
