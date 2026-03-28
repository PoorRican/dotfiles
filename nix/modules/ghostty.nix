# Ghostty terminal emulator — config only (installed outside Nix)
{ ... }:
{
  xdg.configFile."ghostty/config".source = ../../ghostty/config;
  xdg.configFile."ghostty/themes/sourcerer".source = ../../ghostty/themes/sourcerer;
}
