# Personal knowledge management and Helix language-server tools
#
# Helix's language-support table currently has no default language server for
# diff, dunstrc, ghostty, git-* filetypes, hosts, json5, log,
# markdown-rustdoc, rust-format-args, or sshclientconfig. Those remain
# syntax/tree-sitter-only unless we add custom language-server wiring later.
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    # Markdown / notes
    markdown-oxide

    # Shell and config
    bash-language-server
    jinja-lsp
    lemminx
    lua-language-server
    nil
    nixd
    taplo
    tombi
    yaml-language-server

    # Web / structured data
    superhtml
    vscode-langservers-extracted # css/html/json/json-ld language servers
    typescript-language-server

    # Containers
    docker-compose-language-service
    dockerfile-language-server

    # Documents
    texlab

    # Rust / Mojo
    (lib.hiPrio rust-analyzer)
    pixi

    # SQL
    sqls
  ];
}
