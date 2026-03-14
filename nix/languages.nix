# Language runtimes & package managers
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_22
    bun
    ruby
    rustup
    luarocks
  ];
}
