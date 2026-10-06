# Hyprland desktop environment bits for cbox.
# OS-level login/display-manager configuration is installed by
# bin/cbox-switch-to-hyprland-os; Home Manager owns user config and tools.
{ config, dotfiles, lib, pkgs, ... }:
let
  p = config.my.desktop.palette;
in
{
  imports = [ ./desktop-theme.nix ];

  fonts.fontconfig.enable = true;

  # rofi itself comes from pacman (bin/cbox-switch-to-hyprland-os): the
  # nixpkgs build links an older fontconfig that cannot parse Arch's
  # /etc/fonts/conf.d and prints a page of warnings on every launch.
  # rofi-emoji stays for its emoji database (rofi-emoji/all_emojis.txt).
  home.packages = with pkgs; [
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
  # Styled from `my.desktop.palette`: square frame in the accent colour, dimmed
  # low urgency, urgent-colour frame for critical.
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrainsMono Nerd Font 11";
        origin = "top-right";
        # Clear the Waybar strip (reserved height) plus Hyprland's outer gap.
        offset = "(20, 53)";
        width = 380;
        height = "(0, 240)";
        notification_limit = 5;
        padding = 10;
        horizontal_padding = 12;
        text_icon_padding = 10;
        gap_size = 6;
        frame_width = 2;
        corner_radius = 0;
        separator_color = "frame";
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        ellipsize = "end";
        icon_position = "left";
        max_icon_size = 32;
        progress_bar_frame_width = 1;
        progress_bar_corner_radius = 0;
        highlight = "#${p.accent}";
      };
      urgency_low = {
        background = "#${p.bg}";
        foreground = "#${p.muted}";
        frame_color = "#${p.edge}";
        timeout = 5;
      };
      urgency_normal = {
        background = "#${p.bg}";
        foreground = "#${p.fg}";
        frame_color = "#${p.accent}";
        timeout = 8;
      };
      urgency_critical = {
        background = "#${p.bg}";
        foreground = "#${p.fg}";
        frame_color = "#${p.urgent}";
        highlight = "#${p.urgent}";
        timeout = 0;
      };
    };
  };

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
    # flapping applet from tight-looping on the GPU after a wedged reset; both
    # StartLimit keys live in [Unit], not [Service] (systemd rejects them there
    # with "Unknown key 'StartLimitIntervalSec' in section [Service]", leaving
    # the daemons with no rate limit at all).
    #
    # The description is an argument rather than an `// { Unit.Description = }`
    # override: `//` replaces the whole Unit attrset, which would drop PartOf
    # and the StartLimit keys.
    desktopService = description: exec: {
      Unit = {
        Description = description;
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 30;
        StartLimitBurst = 5;
      };
      Service = {
        ExecStart = exec;
        Restart = "always";
        RestartSec = 3;
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
      desktopService "cbox Hyprland status bar (waybar)" "/usr/bin/waybar";

    hypr-waybar-visibility =
      desktopService "cbox fullscreen Waybar edge reveal"
      "${homeDir}/.local/bin/hypr-waybar-visibility --waybar-unit hypr-waybar.service";

    hypr-blueman-applet =
      desktopService "cbox Bluetooth applet (blueman-applet)"
      (hmBin + "/blueman-applet");

    hypr-lxqt-policykit-agent =
      desktopService "cbox Wayland Polkit agent (lxqt-policykit-agent)"
      (hmBin + "/lxqt-policykit-agent");

    hypr-nm-applet =
      desktopService "cbox NetworkManager applet (nm-applet)"
      (hmBin + "/nm-applet");

    # Native Wayland clipboard history. Two long-lived watch processes
    # (text + image) instead of the previous one-shot hypr-start-cliphist.
    hypr-cliphist-text =
      desktopService "cbox Wayland clipboard history watcher (text)"
      "${hmBin}/wl-paste --type text --watch cliphist store";

    hypr-cliphist-image =
      desktopService "cbox Wayland clipboard history watcher (image)"
      "${hmBin}/wl-paste --type image --watch cliphist store";

    # Idle-time lock + DPMS. bin/hypr-idle resolves the live Wayland display
    # from the Hyprland process before exec'ing hypridle with
    # ~/.config/hypr/hypridle.conf. The hyprlock binary it triggers is the
    # system (pacman) build, not the Nix one: the Nix-store build ABRTed on
    # EGL_EXT_platform_base on cbox in Aug 2026.
    hypr-idle =
      desktopService "cbox Hyprland idle lock + DPMS (hypridle)"
      "${homeDir}/.local/bin/hypr-idle";
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
  xdg.configFile."hypr/window-controls.lua".source =
    dotfiles + "/configs/hypr/window-controls.lua";
  # Lock screen + idle handling. PAM must be installed separately via
  # bin/cbox-setup-hyprlock-pam (needs root); without it hyprlock falls back
  # to /etc/pam.d/su -> pam_rootok.so and rejects every non-root password.
  xdg.configFile."hypr/hyprlock.conf" = {
    source = dotfiles + "/configs/hypr/hyprlock.conf";
    force = true;
  };
  xdg.configFile."hypr/hypridle.conf" = {
    source = dotfiles + "/configs/hypr/hypridle.conf";
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

  # Ghostty is the Hyprland terminal; it replaces the hand-written local config.
  xdg.configFile."ghostty/config" = {
    source = dotfiles + "/configs/ghostty/hyprland-config";
    force = true;
  };

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
  home.file.".local/bin/hypr-waybar-visibility" = {
    source = pkgs.writeShellScript "hypr-waybar-visibility" ''
      exec ${pkgs.python313}/bin/python3 ${dotfiles + "/bin/hypr-waybar-visibility"} "$@"
    '';
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
  home.file.".local/bin/cbox-setup-hyprlock-pam" = {
    source = dotfiles + "/bin/cbox-setup-hyprlock-pam";
    executable = true;
  };
  home.file.".local/bin/hypr-idle" = {
    source = dotfiles + "/bin/hypr-idle";
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
