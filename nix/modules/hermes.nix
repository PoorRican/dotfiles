# Hermes Agent — config + installation (installed outside Nix)
# Symlinks all entries from configs/hermes/<profile>/ into ~/.hermes/
{ config, lib, pkgs, dotfiles, ... }:
let
  cfg = config.programs.hermes;
  profileSrc = dotfiles + "/configs/hermes/${cfg.profile}";
  dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/hermes/${cfg.profile}";
  entries = builtins.readDir profileSrc;
  installPath = lib.makeBinPath (with pkgs; [
    curl coreutils gnutar gzip gnugrep gnused perl
  ]);
  pathPrefix = "PATH=${installPath}:$PATH";
in {
  options.programs.hermes = {
    enable = lib.mkEnableOption "hermes-agent";
    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Hermes config profile directory under configs/hermes/.";
    };
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run `hermes update` on every home-manager switch.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mapAttrs' (name: _type:
      lib.nameValuePair ".hermes/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${name}";
      }
    ) entries;

    home.activation.installHermes =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! command -v hermes &> /dev/null; then
          run bash -c 'export ${pathPrefix} && curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash'
        ${lib.optionalString cfg.autoUpdate ''
        else
          run hermes update
        ''}
        fi
      '';
  };
}
