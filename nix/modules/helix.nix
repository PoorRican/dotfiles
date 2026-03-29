# Helix text editor
{ dotfiles, pkgs, ... }:
{
  home.packages = [ pkgs.helix ];
  xdg.configFile."helix/languages.toml".source = dotfiles + "/configs/helix/languages.toml";
}
