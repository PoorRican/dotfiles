# wst server
{ pkgs, ... }:

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

	home.packages = with pkgs; [
		python3
		python314
		python315
	];
}
