# Hermes Agent — config + package installation via upstream flake
# Symlinks all entries from configs/hermes/<profile>/ into ~/.hermes/
{ config, lib, pkgs, dotfiles, inputs, ... }:
let
  cfg = config.programs.hermes;
  profileSrc = dotfiles + "/configs/hermes/${cfg.profile}";
  dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/hermes/${cfg.profile}";
  entries = builtins.readDir profileSrc;
  hermesPackage = inputs.hermes-agent.packages.${pkgs.system}.default;
in {
  options.programs.hermes = {
    enable = lib.mkEnableOption "Hermes Agent";
    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Hermes config profile directory under configs/hermes/.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = hermesPackage;
      description = "Hermes package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = lib.mapAttrs' (name: _type:
      lib.nameValuePair ".hermes/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${name}";
      }
    ) entries;
  };
}
