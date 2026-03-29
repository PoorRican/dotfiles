# Generic server host settings
{ ... }:

{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/server.nix
    ../layers/knowledge-tools.nix
  ];
}
