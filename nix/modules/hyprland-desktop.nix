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

  # Run the notification daemon as a user service instead of tying it to a
  # one-shot compositor start event. This also gives D-Bus a stable owner for
  # org.freedesktop.Notifications after Hyprland config reloads.
  services.dunst.enable = true;

  # Desktop daemons that must survive a Hyprland crash/respawn. Hyprland's
  # `hyprland.start` hook fires only on a fresh compositor process start, so it
  # cannot run when the start-hyprland watchdog respawns Hyprland in safe mode
  # or when "Load config" reloads. Running these as systemd user services with
  # Restart=always means the (still-alive) user manager respawns them whenever
  # they die. They are enabled on default.target because LightDM does not
  # activate graphical-session.target for this session.
  # The Hyprland Lua config still `systemctl --user start`s these at
  # hyprland.start and on `config.reloaded` so the environment is current and
  # they are up even before their default.target enablement has taken effect.
  systemd.user.services = let
    homeDir = config.home.homeDirectory;
    hmBin = homeDir + "/.local/state/nix/profiles/home-manager/home-path/bin";

    # Shared shape for the cbox desktop daemons. Each one owns a single long-lived
    # process; the user manager respawns it on death. StartLimit* keeps a
    # flapping applet from tight-looping on the GPU after a wedged reset.
    desktopService = exec: {
      Unit = {
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = exec;
        Restart = "always";
        RestartSec = 3;
        StartLimitIntervalSec = 30;
        StartLimitBurst = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  in {
    # Reapplies the cbox grave-key runtime binds (see bin/pk-wiki --watch-binds).
    # Targets graphical-session.target like before; started explicitly from the
    # Hyprland autostart hook because LightDM does not activate that target.
    hypr-runtime-binds = {
      Unit = {
        Description = "Reapply cbox Hyprland runtime key bindings";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${homeDir}/.local/bin/pk-wiki --watch-binds";
        Restart = "always";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    hypr-waybar =
      desktopService "/usr/bin/waybar"
      // { Unit.Description = "cbox Hyprland status bar (waybar)"; };

    hypr-blueman-applet =
      desktopService (hmBin + "/blueman-applet")
      // { Unit.Description = "cbox Bluetooth applet (blueman-applet)"; };

    hypr-lxqt-policykit-agent =
      desktopService (hmBin + "/lxqt-policykit-agent")
      // { Unit.Description = "cbox Wayland Polkit agent (lxqt-policykit-agent)"; };

    hypr-nm-applet =
      desktopService (hmBin + "/nm-applet")
      // { Unit.Description = "cbox NetworkManager applet (nm-applet)"; };

    # Native Wayland clipboard history. Two long-lived watch processes
    # (text + image) instead of the previous one-shot hypr-start-cliphist.
    hypr-cliphist-text =
      desktopService "${hmBin}/wl-paste --type text --watch cliphist store"
      // { Unit.Description = "cbox Wayland clipboard history watcher (text)"; };

    hypr-cliphist-image =
      desktopService "${hmBin}/wl-paste --type image --watch cliphist store"
      // { Unit.Description = "cbox Wayland clipboard history watcher (image)"; };
  };

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
  xdg.configFile."rofi/prose-symbols.tsv".source = lib.mkDefault (dotfiles + "/configs/rofi/prose-symbols.tsv");
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
  home.file.".local/bin/hypr-prose-symbol-picker" = {
    source = dotfiles + "/bin/hypr-prose-symbol-picker";
    executable = true;
  };
  home.file.".local/bin/hypr-keybindings-menu" = {
    source = dotfiles + "/bin/hypr-keybindings-menu";
    executable = true;
  };
  home.file.".local/bin/waybar-hypr-workspace" = {
    source = dotfiles + "/bin/waybar-hypr-workspace";
    executable = true;
  };
  home.file.".local/bin/sysadmin" = {
    source = dotfiles + "/bin/sysadmin";
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

  xdg.dataFile."applications/cbox-sysadmin.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=cbox Sysadmin
    GenericName=Sysadmin workspace
    Comment=Open the sysadmin Zellij session
    Exec=${config.home.homeDirectory}/.local/bin/sysadmin --show
    Terminal=false
    Categories=Utility;
    StartupWMClass=com.cbox.sysadmin
    Keywords=Sysadmin;Hermes;Zellij;Terminal;
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
