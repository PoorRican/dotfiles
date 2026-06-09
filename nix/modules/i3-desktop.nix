# i3 desktop environment bits for cbox.
{ dotfiles, pkgs, ... }:
let
  polybarWithI3 = pkgs.polybar.override {
    i3Support = true;
    pulseSupport = true;
  };
in
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    i3
    i3lock
    alacritty
    rofi
    dunst
    libnotify
    pavucontrol
    networkmanagerapplet
    picom
    xkill
    bluez
    blueman
    feh
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  xdg.configFile."i3/config".source = dotfiles + "/configs/i3/config";
  xdg.configFile."rofi/config.rasi".source = dotfiles + "/configs/rofi/config.rasi";
  xdg.configFile."rofi/themes/sourcerer.rasi".source = dotfiles + "/configs/rofi/themes/sourcerer.rasi";

  services.polybar = {
    enable = true;
    package = polybarWithI3;
    config = dotfiles + "/configs/polybar/config.ini";
    script = "polybar main &";
  };
}
