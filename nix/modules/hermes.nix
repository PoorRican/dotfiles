# Hermes Agent — config only (installed outside Nix)
# Symlinks all entries from configs/hermes/<profile>/ into ~/.hermes/
# Usage: (import ./nix/modules/hermes.nix).dgx
let
  mkProfile = profile:
    { config, lib, dotfiles, ... }:
    let
      profileSrc = dotfiles + "/configs/hermes/${profile}";
      dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/hermes/${profile}";
      entries = builtins.readDir profileSrc;
    in {
      home.file = lib.mapAttrs' (name: _type:
        lib.nameValuePair ".hermes/${name}" {
          source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${name}";
        }
      ) entries;
    };
in {
  default = mkProfile "default";
  dgx = mkProfile "dgx";
  server = mkProfile "server";
}
