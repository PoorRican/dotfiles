# Helix PKM language-server profile pattern

## Context

When adding many Helix language servers to this dotfiles repo, prefer a separate Home Manager profile such as `nix/profiles/pkm.nix` rather than expanding `dev-core.nix` or `dev-extra.nix`. Import that profile only on hosts that should carry the PKM/editor-heavy toolchain.

## Workflow

1. Check the upstream Helix language support table for each requested language and note whether it actually has a default language server.
2. Install only packages that provide language-server binaries; leave pure syntax/tree-sitter-only languages alone unless adding custom LSP wiring.
3. Put the package set in `nix/profiles/pkm.nix` and import it from the target host, e.g. `nix/hosts/cbox.nix`.
4. Add explicit Helix overrides in `configs/helix/languages.toml` when either:
   - choosing between multiple defaults, or
   - the package binary name differs from the Helix default / needs args.
5. Stage any new profile/config files before normal flake evaluation if using a `git+file` flake path.
6. Verify with Home Manager evals and `hx --health <language>` for every requested language.
7. Apply on the target host with `home-manager switch --flake .#<host>` only after eval passes.

## Package / Helix mappings used

- Markdown: `markdown-oxide`; override `markdown` to use only `markdown-oxide` if `marksman` is not installed.
- Bash: `bash-language-server`.
- CSS / JSON / JSON-LD: `vscode-langservers-extracted`.
- Docker Compose: `docker-compose-language-service` (`docker-compose-langserver`).
- Dockerfile: `dockerfile-language-server` (`docker-langserver`).
- HTML: prefer `superhtml` over the older VS Code HTML server when the user asks for the more modern option; override Helix `html` to `superhtml`.
- Jinja: `jinja-lsp` with `args = ["--stdio"]`; Helix may not have a default server for Jinja.
- LaTeX: `texlab`.
- Lua: `lua-language-server`.
- Mojo: `pixi` provides the Helix default `mojo-lsp-server` command path.
- Nix: install both `nil` and `nixd` if requested broadly.
- Rust: `rust-analyzer`; if `rustup` is also installed, wrap as `(lib.hiPrio rust-analyzer)` to avoid `home-manager-path` conflict with `rustup/bin/rust-analyzer`.
- SQL: `sqls`; override Helix `sql` to `sqls` because Helix may not configure a SQL server by default.
- TOML: `taplo` and `tombi`.
- TSX / TypeScript: `typescript-language-server`.
- XML: `lemminx`; override Helix `xml` to `lemminx` because Helix may not configure an XML server by default.
- YAML: `yaml-language-server`; override YAML to avoid a spurious missing `ansible-language-server` health warning unless Ansible support is explicitly wanted.

## Languages that may be syntax-only in Helix

At the time of the referenced session, Helix's language support table listed no default language server for these requested filetypes: `diff`, `dunstrc`, `ghostty`, `git-commit`, `git-attributes`, `git-config`, `git-ignore`, `git-notes`, `git-rebase`, `hosts`, `json5`, `log`, `markdown-rustdoc`, `rust-format-args`, and `sshclientconfig`.

For those, do not invent packages or custom wiring unless the user explicitly asks for a non-default external LSP. Install nothing beyond Helix's built-in syntax support.

## Verification snippets

Useful checks after switching:

```bash
command -v markdown-oxide bash-language-server vscode-css-language-server \
  docker-compose-langserver docker-langserver texlab lua-language-server \
  pixi nil nixd rust-analyzer taplo tombi typescript-language-server \
  yaml-language-server superhtml jinja-lsp lemminx sqls

for lang in markdown bash css docker-compose dockerfile html jinja json json-ld \
  latex lua mojo nix rust sql toml tsx typescript xml yaml; do
  hx --health "$lang"
done
```

Treat `hx --health rust` missing `lldb-dap` as a debug-adapter issue, not an LSP failure, unless the user asked for debugging support.
