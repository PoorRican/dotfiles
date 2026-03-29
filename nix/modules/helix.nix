# Helix text editor
{ pkgs, ... }:
{
  home.packages = [ pkgs.helix ];
  xdg.configFile."helix/languages.toml".source = ../../helix/languages.toml;
}
