{ config, lib, pkgs, ... }:

let
  cfg = config.my.obsidian-sync;
  mkVaultService = vault:
    lib.nameValuePair "obsidian-sync-${vault.name}" {
      Unit = {
        Description = "Obsidian Headless continuous sync for ${vault.name} vault";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/ob sync --continuous --path ${lib.escapeShellArg vault.path}";
        Restart = "always";
        RestartSec = 10;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
in
{
  options.my.obsidian-sync = {
    enable = lib.mkEnableOption "Obsidian Headless continuous sync user services";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodePackages.obsidian-headless;
      defaultText = lib.literalExpression "pkgs.nodePackages.obsidian-headless";
      description = "Package providing the 'ob' executable.";
    };

    vaults = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Short service-safe vault name, e.g. 'kairos'.";
          };

          path = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path to the local Obsidian vault.";
          };
        };
      });
      default = [ ];
      example = [
        { name = "kairos"; path = "/home/swe/wikis/kairos"; }
        { name = "memex"; path = "/home/swe/wikis/memex"; }
      ];
      description = "Vaults to keep in continuous sync via Obsidian Headless.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services = lib.mapAttrs'
      (_: service: service)
      (builtins.listToAttrs (map mkVaultService cfg.vaults));
  };
}
