# wst server
{ pkgs, lib, inputs, ... }:

{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/server.nix
		../profiles/dev-core.nix
		#../profiles/dev-extra.nix
		# not used at this moment
		#../layers/knowledge-tools.nix
    # Hermes without the rest of dev-extra; the private flake extends this
    # host with the kairos-ops profile and the host gateway that serves it.
    ../modules/hermes.nix
  ];

  programs.hermes.enable = lib.mkDefault true;

  # This host composes the private profile flake; record its revision for
  # hermes-profile-capture provenance.
  programs.hermes.capture.sourceRevisions."agent-profiles" = inputs.agent-profiles.rev or null;

	home.packages = with pkgs; [
		python314
		python314Packages.huggingface-hub
		tree
	];
}
