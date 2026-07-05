# Zellij terminal multiplexer
{ dotfiles, pkgs, ... }:
{
  home.packages = [ pkgs.zellij ];
  xdg.configFile."zellij/config.kdl".source = dotfiles + "/configs/zellij/config.kdl";
  xdg.configFile."zellij/layouts/sourcerer-layout.kdl".source = dotfiles + "/configs/zellij/layouts/sourcerer-layout.kdl";
  xdg.configFile."zellij/layouts/pk-wiki.kdl".source = dotfiles + "/configs/zellij/layouts/pk-wiki.kdl";
  xdg.configFile."zellij/layouts/sysadmin.kdl".source = dotfiles + "/configs/zellij/layouts/sysadmin.kdl";
}
