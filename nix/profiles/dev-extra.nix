# miscellaneous dev tools. Coding agents will expect these
{ pkgs, lib, ... }:
{
  imports = [
    ../modules/claude-code.nix
    ../modules/codex.nix
    ../modules/hermes.nix
  ];

  programs.claude-code.enable = lib.mkDefault true;
  programs.codex.enable = lib.mkDefault true;
  programs.hermes.enable = lib.mkDefault true;

  home.packages = with pkgs; [
		# cli tools
		ripgrep
		fd
		bat
		jq
		fzf  # required by neovim. de-dup?

		# LSPs
    cmake-format
    cppcheck
    pyright

		# misc
		helix
		rclone
  ];
}
