# Zellij remote WASM plugin pinning and cache behavior

## When this applies

Use this when maintaining the user's Home Manager-managed Zellij config in the dotfiles repo, especially `configs/zellij/config.kdl`, `configs/zellij/layouts/*.kdl`, or `nix/modules/zellij.nix`.

## Key lesson

Zellij can cache remote HTTP(S) WASM plugins by URL. A config URL such as:

```kdl
https://github.com/<owner>/<repo>/releases/latest/download/plugin.wasm
```

means "latest" to GitHub, but it is a stable URL string to Zellij. If the release asset changes behind the same `latest` URL, Zellij may keep using the stale cached WASM. This can show up as UI/plugin glitches after a Zellij upgrade even when `zellij --version` is already current.

## Preferred dotfiles pattern

Pin remote WASM plugin URLs to exact GitHub release asset URLs:

```kdl
plugin location="https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm" {
    // plugin config
}
```

When a plugin version is intentionally bumped, the URL changes, so Zellij treats it as a new remote resource and downloads/recompiles it instead of reusing the old `latest` cache entry.

## Investigation checklist

1. Inspect active Zellij version and config source:
   ```sh
   zellij --version
   zellij setup --check
   readlink -f ~/.config/zellij/config.kdl
   ```
2. Search the dotfiles Zellij config for remote WASM URLs:
   ```sh
   git grep -n 'releases/latest/download/.*\.wasm' -- configs/zellij
   git grep -n 'https://github.com/.*\.wasm' -- configs/zellij
   ```
3. Compare local cached WASM sizes/checksums with latest GitHub release assets if cache staleness is suspected.
4. Patch `configs/zellij/*.kdl` to exact release URLs, not `latest`.
5. Validate the edited config directly:
   ```sh
   zellij --config /path/to/configs/zellij/config.kdl --config-dir /path/to/configs/zellij setup --check
   ```
6. Stage only the Zellij files if the repo has unrelated dirty work:
   ```sh
   git add -- configs/zellij/config.kdl configs/zellij/layouts/<layout>.kdl
   ```

## Applying the change

Home Manager must deploy the edited config, then Zellij sessions must restart for layout/plugin changes:

```sh
home-manager switch --flake .#<host>
zellij kill-all-sessions
zellij
```

Avoid running `home-manager switch` automatically when the dotfiles repo has many unrelated staged/dirty changes unless the user explicitly wants the full generation applied.

## Longer-term option

For a more declarative setup, fetch WASM plugins through Nix/Home Manager with fixed hashes and point Zellij at `file:` URLs under a managed local plugin directory. That turns plugin updates into normal dotfiles/Nix changes instead of relying on Zellij's remote cache behavior.
