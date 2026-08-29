# Ghostty terminal emulator — config only (installed outside Nix)
# TODO: "installed outside Nix" might only be true for `#mbp`, which is no longer relevant
{ dotfiles, ... }:
{
  xdg.configFile."ghostty/config".source = dotfiles + "/configs/ghostty/config";
  xdg.configFile."ghostty/themes/sourcerer".source = dotfiles + "/configs/ghostty/themes/sourcerer";
}
