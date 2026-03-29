# non-negotiable packages for all configurations
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    coreutils-full
    yazi
		uv
  ];
}
