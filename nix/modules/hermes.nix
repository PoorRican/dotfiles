# Hermes Agent — config + installation (installed outside Nix)
# Symlinks all entries from configs/hermes/<profile>/ into ~/.hermes/
{ config, lib, pkgs, dotfiles, ... }:
let
  cfg = config.programs.hermes;
  profileSrc = dotfiles + "/configs/hermes/${cfg.profile}";
  dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/hermes/${cfg.profile}";
  entries = builtins.readDir profileSrc;
  ext = import ./lib/mk-external-install.nix { inherit lib pkgs; } {
    name = "hermes-agent";
    binary = "hermes";
    installCmd = "curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash";
    updateCmd = "hermes update";
    useCurl = true;
    extraPkgs = [ pkgs.git pkgs.awk ];
  };
in {
  options.programs.hermes = ext.options // {
    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Hermes config profile directory under configs/hermes/.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mapAttrs' (name: _type:
      lib.nameValuePair ".hermes/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${name}";
      }
    ) entries;

    home.activation.installHermes = ext.mkActivation cfg;
  };
}
