# macOS (MacBook Pro) host-specific settings
{ pkgs, lib, config, ... }:
{
  home.sessionVariables = {
    DYLD_FALLBACK_LIBRARY_PATH = "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager/home-path/lib";
  };

  targets.darwin.copyApps.enableChecks = false;
}
