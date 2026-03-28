# TODO: this should be a module
{ pkgs, ... }:
{
  home.packages = with pkgs; [
		codex
		claude-code

		# cli tools - required by agents above
		ripgrep
		fd
		bat
		jq
		fzf  # required by neovim. de-dup?

		# LSPs - required by agents above
    cmake-format
    cppcheck
    pyright

		# misc
		helix
		rclone
  ];
}
