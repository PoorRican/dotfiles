# Core development tools
{ pkgs, ... }:
{
  imports = [
    ../modules/git.nix
    ../modules/helix.nix
    ../modules/neovim.nix
  ];

  home.packages = with pkgs; [
    direnv
    cmake
    pyright

    nodejs_22
    bun
    rustup
    luarocks

    # databases
    sqlite
    postgresql_17_jit
  ];
}
