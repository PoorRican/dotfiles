# macOS (MacBook Pro) host-specific settings
{ pkgs, config, ... }:
{
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

  targets.darwin.copyApps.enableChecks = false;  # this might be necessary for GUI apps
}
