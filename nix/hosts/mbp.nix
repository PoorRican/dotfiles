# macOS (MacBook Pro) host-specific settings
{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    imsg
    iterm2
  ];

  home.sessionVariables = {
    DYLD_FALLBACK_LIBRARY_PATH = "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager/home-path/lib";
  };

  targets.darwin.copyApps.enableChecks = false;
}
