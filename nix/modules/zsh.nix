# Zsh shell configuration
{ pkgs, ... }:
{
  home.packages = [ pkgs.oh-my-zsh ];
  home.file.".zshenv".source = ../../zsh/zshenv;
  home.file.".zshrc".source = ../../zsh/zshrc;
  home.file.".zsh" = {
    source = ../../zsh/modules;
    recursive = true;
  };
}
