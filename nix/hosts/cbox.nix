# cbox server
{ lib, pkgs, ... }:

{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/server.nix
    ../profiles/i3-desktop.nix
    ../profiles/hyprland-desktop.nix
    ../profiles/dev-core.nix
    ../profiles/dev-extra.nix
    ../profiles/pkm.nix
    # not used at this moment
    #../layers/knowledge-tools.nix
  ];

  # The shared Neovim module manages the full ~/.config/nvim tree and installs
  # the Neovim binary package directly. Keep Home Manager's program module off
  # here so it does not generate ~/.config/nvim/init.lua alongside the symlinked
  # config tree.
  programs.neovim.enable = lib.mkForce false;
  programs.agent-skills.host = "cbox";

  home.packages = with pkgs; [
		noto-fonts
		noto-fonts-cjk-sans
		noto-fonts-color-emoji
	];
}
