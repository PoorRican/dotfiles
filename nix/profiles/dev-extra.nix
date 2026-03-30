# miscellaneous dev tools. Coding agents will expect these
{ pkgs, ... }:
{
  imports = [
    ../modules/claude-code.nix
  ];

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
