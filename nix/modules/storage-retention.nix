# computebox only. Do not add a second global Nix store-GC timer.
{ lib, ... }:
let
  # Copy just the reviewed script to the store; selective live deployment roots
  # it separately, without activating unrelated desktop changes.
  script = builtins.path {
    path = ../../bin/cbox-storage-retention.py;
    name = "cbox-storage-retention.py";
  };
  service = description: action: {
    Unit.Description = description;
    Service = {
      Type = "oneshot";
      ExecStart = "/usr/bin/python3 ${script} ${action}" + (if action == "uv" then " --apply" else "");
      Nice = 15;
      IOSchedulingClass = "idle";
      UMask = "0077";
      TimeoutStartSec = "45min";
      SuccessExitStatus = "75"; # A busy UV/maintenance lock is deferred, not forced.
    };
  };
  timer = description: name: calendar: {
    Unit.Description = description;
    Timer = {
      OnCalendar = calendar;
      RandomizedDelaySec = "10min";
      Persistent = true;
      Unit = "cbox-retention-${name}.service";
    };
    # Only UV has a supported apply boundary. Other services preview, and
    # future Home Manager activation must not enable their expiry timers.
    Install.WantedBy = if name == "uv" then [ "timers.target" ] else [];
  };
in {
  # Determinate Nixd remains the sole automatic store-GC owner. The user timer
  # only previews explicit profile-generation roots; expiry is unavailable.
  nix.gc.automatic = lib.mkForce false;
  systemd.user.services = {
    cbox-retention-nix = service "Nix profile retention: 30 days and five distinct rollback closures" "nix";
    cbox-retention-images = service "Unused Docker image retention: older than 14 days, explicit holds" "images";
    cbox-retention-build-cache = service "Local default-builder cache retention: unused 14 days, 100GB target/20GB reserve" "build-cache";
    cbox-retention-uv = service "Prune unused UV entries; defer while active jobs hold cache locks" "uv";
  };
  systemd.user.timers = {
    cbox-retention-nix = timer "Daily Nix profile-root retention" "nix" "*-*-* 04:00:00";
    cbox-retention-images = timer "Weekly unused-image retention" "images" "Sun *-*-* 05:00:00";
    cbox-retention-build-cache = timer "Weekly old builder-cache retention" "build-cache" "Sun *-*-* 05:20:00";
    cbox-retention-uv = timer "Hourly unused-UV retry" "uv" "hourly";
  };
}
