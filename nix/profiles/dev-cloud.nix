# Cloud & infrastructure CLIs
{ pkgs, lib, ... }:
{
  imports = [
    ../modules/pulumi.nix
  ];

  programs.pulumi.enable = lib.mkDefault true;

  home.packages = with pkgs; [
    google-cloud-sdk
    awscli2
  ];
}
