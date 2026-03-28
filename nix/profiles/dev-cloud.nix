# Cloud & infrastructure CLIs
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    google-cloud-sdk
    pulumi
    pulumiPackages.pulumi-python
    pulumiPackages.pulumi-nodejs
    awscli2
  ];
}
