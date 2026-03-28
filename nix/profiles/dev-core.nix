# Core development tools
{ pkgs, ... }:
{
  home.packages = with pkgs; [
		# git
		# TODO: setup git config
    git
    git-lfs
    gh

    direnv
    cmake
    pyright  # TODO: might be required for nvim?

    nodejs_22
    bun
    rustup
    luarocks

		# databases
    sqlite
    postgresql_17_jit
  ];
}
