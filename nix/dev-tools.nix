# Development tools, LSPs, build tools, libraries
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    git-lfs
    direnv
    gh
    cmake
    cmake-format
    cppcheck
    pyright
    sqlite
    postgresql_17_jit
    cairo
    cairosvg
  ];
}
