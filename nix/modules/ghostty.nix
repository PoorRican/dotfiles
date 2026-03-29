# Ghostty terminal emulator — config only (installed outside Nix)
{ dotfiles, ... }:
{
  xdg.configFile."ghostty/config".source = dotfiles + "/configs/ghostty/config";
  xdg.configFile."ghostty/themes/sourcerer".source = dotfiles + "/configs/ghostty/themes/sourcerer";
}
