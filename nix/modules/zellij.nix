# Zellij terminal multiplexer
{ pkgs, ... }:
{
  home.packages = [ pkgs.zellij ];
  xdg.configFile."zellij/config.kdl".source = ../../zellij/config.kdl;
  xdg.configFile."zellij/layouts/sourcerer-layout.kdl".source = ../../zellij/layouts/sourcerer-layout.kdl;
}
