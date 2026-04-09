# macOS (MacBook Pro) host-specific settings
{ pkgs, config, ... }:
{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/dev-core.nix
    ../profiles/dev-cloud.nix
    ../profiles/dev-extra.nix
		#../profiles/server.nix
    ../modules/ghostty.nix
  ];

  programs.hermes.profile = "mbp";

  home.packages = with pkgs; [
    imsg
    iterm2

    # dev - misc
    nmap
    ruby
    firebase-tools

    # dev - image tools
    cairo
    cairosvg
    graphviz
  ];

  home.sessionVariables = {
    DYLD_FALLBACK_LIBRARY_PATH = "${config.home.homeDirectory}/.local/state/nix/profiles/home-manager/home-path/lib";
  };

  targets.darwin.copyApps.enableChecks = false;
}
