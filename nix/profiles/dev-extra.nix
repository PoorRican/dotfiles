# miscellaneous dev tools. Coding agents will expect these
{ pkgs, lib, ... }:
{
  imports = [
    ../modules/claude-code.nix
    ../modules/codex.nix
    ../modules/hermes.nix
    # OMP joins the other coding-agent CLIs here; the module itself handles the
    # Bun global install and can still be disabled per host with mkForce.
    ../modules/omp.nix
  ];

  programs.claude-code.enable = lib.mkDefault true;
  programs.codex.enable = lib.mkDefault true;
  programs.hermes.enable = lib.mkDefault true;
  # Default-on for dev machines, but intentionally not forced so host profiles
  # can opt out without editing this shared profile.
  programs.omp.enable = lib.mkDefault true;

  home.packages = with pkgs; [
		# cli tools
		ripgrep
		fd
		bat
		jq
		fzf  # required by neovim. de-dup?
		lefthook

		# LSPs
    cmake-format
    cppcheck
    pyright

		# misc
		helix
		rclone
  ];
}
