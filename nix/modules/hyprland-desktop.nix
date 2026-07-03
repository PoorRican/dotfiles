# Hyprland desktop environment bits for cbox.
# OS-level login/display-manager configuration is installed by
# bin/cbox-switch-to-hyprland-os; Home Manager owns user config and tools.
{ config, dotfiles, lib, pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    rofi
    rofi-emoji
    wl-clipboard
    cliphist
    wtype
    dunst
    libnotify
    pavucontrol
    networkmanagerapplet
    bluez
    blueman
    lxqt.lxqt-policykit
    jq
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  home.sessionVariables = {
    BROWSER = "vivaldi-stable";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    MOZ_ENABLE_WAYLAND = "1";
  };

  xdg.configFile."hypr/hyprland.lua" = {
    source = dotfiles + "/configs/hypr/hyprland.lua";
    force = true;
  };
  xdg.configFile."waybar/config.jsonc" = {
    source = dotfiles + "/configs/waybar/config.jsonc";
    force = true;
  };
  xdg.configFile."waybar/style.css" = {
    source = dotfiles + "/configs/waybar/style.css";
    force = true;
  };
  xdg.configFile."rofi/config.rasi".source = lib.mkDefault (dotfiles + "/configs/rofi/config.rasi");
  xdg.configFile."rofi/symbols.tsv".source = lib.mkDefault (dotfiles + "/configs/rofi/symbols.tsv");
  xdg.configFile."rofi/themes/sourcerer.rasi".source = lib.mkDefault (dotfiles + "/configs/rofi/themes/sourcerer.rasi");

  # Replace the smoke-test tty autostart with a neutral login profile. LightDM
  # owns Hyprland startup once the OS-level switch script has been run.
  home.file.".zprofile" = {
    source = dotfiles + "/configs/zsh/cbox-zprofile";
    force = true;
  };

  home.file.".local/bin/cbox-switch-to-hyprland-os" = {
    source = dotfiles + "/bin/cbox-switch-to-hyprland-os";
    executable = true;
  };
  home.file.".local/bin/hypr-start-cliphist" = {
    source = dotfiles + "/bin/hypr-start-cliphist";
    executable = true;
  };
  home.file.".local/bin/hypr-clipboard-menu" = {
    source = dotfiles + "/bin/hypr-clipboard-menu";
    executable = true;
  };
  home.file.".local/bin/hypr-symbol-picker" = {
    source = dotfiles + "/bin/hypr-symbol-picker";
    executable = true;
  };
  home.file.".local/bin/pk-wiki" = {
    source = dotfiles + "/bin/pk-wiki";
    executable = true;
  };

  xdg.dataFile."applications/project-kairos-wiki.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Project Kairos Wiki
    GenericName=Wiki workspace
    Comment=Open the Project Kairos wiki Zellij session
    Exec=${config.home.homeDirectory}/.local/bin/pk-wiki --show
    Terminal=false
    Categories=Utility;
    StartupWMClass=com.projectkairos.wiki
    Keywords=Kairos;Wiki;Zellij;Neovim;pi;
  '';

  xdg.configFile."mimeapps.list" = {
    force = true;
    text = ''
      [Default Applications]
      text/html=vivaldi-stable.desktop
      x-scheme-handler/http=vivaldi-stable.desktop
      x-scheme-handler/https=vivaldi-stable.desktop
      x-scheme-handler/about=vivaldi-stable.desktop
      x-scheme-handler/unknown=vivaldi-stable.desktop

      [Added Associations]
      text/html=vivaldi-stable.desktop;
      x-scheme-handler/http=vivaldi-stable.desktop;
      x-scheme-handler/https=vivaldi-stable.desktop;
    '';
  };
}
