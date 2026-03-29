# Zsh shell configuration
{ dotfiles, pkgs, ... }:
{
  home.packages = [ pkgs.oh-my-zsh ];
  home.file.".zshenv".source = dotfiles + "/configs/zsh/zshenv";
  home.file.".zshrc".source = dotfiles + "/configs/zsh/zshrc";
  home.file.".zsh" = {
    source = dotfiles + "/configs/zsh/modules";
    recursive = true;
  };
}
