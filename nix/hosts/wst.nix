# wst server
{ pkgs, lib, ... }:

{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/server.nix
		../profiles/dev-core.nix
		#../profiles/dev-extra.nix
		# not used at this moment
		#../layers/knowledge-tools.nix
  ];

  programs.hermes.enable = lib.mkDefault true;

	home.packages = with pkgs; [
		python314
		python314Packages.huggingface-hub
		tree
	];
}
