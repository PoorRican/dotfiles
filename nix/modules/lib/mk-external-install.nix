# Helper for external tool modules installed outside Nix.
# Returns a module fragment with enable/autoUpdate options and an activation script.
#
# Usage:
#   mkExternalInstall {
#     name = "claude-code";
#     binary = "claude";
#     installCmd = "curl -fsSL https://claude.ai/install.sh | bash";
#     updateCmd = "claude update";
#     useCurl = true;  # prepend nix-store tools to PATH for curl|bash scripts
#   }
{ lib, pkgs }:
{ name
, binary
, installCmd
, updateCmd
, useCurl ? false
}:
let
  # POSIX tools that curl|bash install scripts commonly need
  installPath = lib.makeBinPath (with pkgs; [
    curl coreutils gnutar gzip gnugrep gnused perl
  ]);
  wrapCmd = cmd:
    if useCurl
    then "bash -c 'export PATH=${installPath}:$PATH && ${cmd}'"
    else cmd;
in {
  options = {
    enable = lib.mkEnableOption name;
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run the update command on every home-manager switch.";
    };
  };
  mkActivation = cfg:
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! command -v ${binary} &> /dev/null; then
        run ${wrapCmd installCmd}
      ${lib.optionalString cfg.autoUpdate ''
      else
        run ${wrapCmd updateCmd}
      ''}
      fi
    '';
}
