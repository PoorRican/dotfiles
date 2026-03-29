# Tmux terminal multiplexer
{ dotfiles, pkgs, ... }:
{
  home.packages = [ pkgs.tmux ];
  xdg.configFile."tmux/tmux.conf".source = dotfiles + "/configs/tmux/tmux.conf";
}
