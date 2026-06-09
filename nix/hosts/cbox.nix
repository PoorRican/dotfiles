# cbox server
{ lib, pkgs, ... }:

{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/server.nix
    ../profiles/i3-desktop.nix
    ../profiles/dev-core.nix
    ../profiles/dev-extra.nix
    # not used at this moment
    #../layers/knowledge-tools.nix
  ];

  # The shared Neovim module manages the full ~/.config/nvim tree and also
  # enables Home Manager's Neovim program module. On this 26.05 cbox switch,
  # that program module generates ~/.config/nvim/init.lua and collides with
  # the symlinked config tree. Keep upstream's shared module intact and make
  # cbox package-only for now.
  programs.neovim.enable = lib.mkForce false;
  home.packages = [ pkgs.neovim ];
}
