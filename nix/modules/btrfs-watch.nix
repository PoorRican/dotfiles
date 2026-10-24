# computebox: independent alert-only monitoring, never a cleanup controller.
{ pkgs, ... }:
let
  script = builtins.path {
    path = ../../bin/cbox-btrfs-watch.py;
    name = "cbox-btrfs-watch.py";
  };
in {
  systemd.user.services.cbox-btrfs-watch = {
    Unit.Description = "Read-only Btrfs metadata/headroom monitor";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 -B ${script}"
        + " --uuid 12019150-ad54-405b-b8e7-ffa3a112ed02 --mount /"
        + " --state-dir %h/.local/state/btrfs-watch"
        + " --btrfs ${pkgs.btrfs-progs}/bin/btrfs"
        + " --findmnt ${pkgs.util-linux}/bin/findmnt"
        + " --notify-send ${pkgs.libnotify}/bin/notify-send";
      UMask = "0077";
      NoNewPrivileges = true;
      Nice = 15;
      IOSchedulingClass = "idle";
      TimeoutStartSec = "60s";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
  systemd.user.timers.cbox-btrfs-watch = {
    Unit.Description = "Check Btrfs metadata and allocation headroom at 08:00 and 20:00";
    Timer = {
      OnCalendar = "*-*-* 08,20:00:00";
      Persistent = false;
      AccuracySec = "10s";
      RandomizedDelaySec = "0";
      Unit = "cbox-btrfs-watch.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
