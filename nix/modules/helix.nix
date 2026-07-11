# Helix text editor
{ dotfiles, pkgs, ... }:
{
  home.packages = [ pkgs.helix ];
  xdg.configFile."helix/languages.toml".source = dotfiles + "/configs/helix/languages.toml";
  xdg.configFile."helix/config.toml".source = dotfiles + "/configs/helix/config.toml";
}
