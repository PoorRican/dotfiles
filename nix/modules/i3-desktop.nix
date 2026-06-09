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
    rofi-emoji
    clipmenu
    dunst
    libnotify
    pavucontrol
    networkmanagerapplet
    snixembed
    picom
    xkill
    xclip
    xdotool
    xinput
    bluez
    blueman
    feh
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  xdg.configFile."i3/config".source = dotfiles + "/configs/i3/config";
  xdg.configFile."rofi/config.rasi".source = dotfiles + "/configs/rofi/config.rasi";
  xdg.configFile."rofi/symbols.tsv".source = dotfiles + "/configs/rofi/symbols.tsv";
  xdg.configFile."rofi/themes/sourcerer.rasi".source = dotfiles + "/configs/rofi/themes/sourcerer.rasi";

  home.file.".local/bin/i3-natural-scroll" = {
    source = dotfiles + "/bin/i3-natural-scroll";
    executable = true;
  };
  home.file.".local/bin/i3-start-clipmenud" = {
    source = dotfiles + "/bin/i3-start-clipmenud";
    executable = true;
  };
  home.file.".local/bin/i3-clipboard-menu" = {
    source = dotfiles + "/bin/i3-clipboard-menu";
    executable = true;
  };
  home.file.".local/bin/i3-symbol-picker" = {
    source = dotfiles + "/bin/i3-symbol-picker";
    executable = true;
  };
  home.file.".local/bin/i3-keybindings-menu" = {
    source = dotfiles + "/bin/i3-keybindings-menu";
    executable = true;
  };
  home.file.".local/bin/i3-vivaldi" = {
    source = dotfiles + "/bin/i3-vivaldi";
    executable = true;
  };
  home.file.".local/bin/i3-quake-terminal" = {
    source = dotfiles + "/bin/i3-quake-terminal";
    executable = true;
  };

  services.polybar = {
    enable = true;
    package = polybarWithI3;
    config = dotfiles + "/configs/polybar/config.ini";
    script = "polybar main &";
  };
}
