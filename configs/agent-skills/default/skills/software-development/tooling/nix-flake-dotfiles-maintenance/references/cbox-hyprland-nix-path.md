# cbox Hyprland: `nix` missing from new shells

## Symptom

New terminals under the cbox Hyprland session report `nix: command not found`, even though the multi-user Determinate Nix install is healthy and `/nix/var/nix/profiles/default/bin/nix` exists.

Typical evidence:

```bash
command -v nix || true
ls -l /nix/var/nix/profiles/default/bin/nix
systemctl status nix-daemon.service --no-pager
```

The daemon can be active while `nix` is still absent from the shell PATH.

## Root cause pattern

Hyprland Lua config can intentionally set a minimal session environment, for example:

```lua
hl.env("PATH", hmBin .. ":/usr/local/bin:/usr/bin:/bin")
```

If the session also inherited Nix's exported guard:

```text
__ETC_PROFILE_NIX_SOURCED=1
```

then new zsh shells source `~/.zshenv`, try to source `nix-daemon.sh`, and `nix-daemon.sh` immediately returns because it believes it has already run. Result: `/nix/var/nix/profiles/default/bin` never gets re-added to PATH.

## Durable repo fix

1. In `configs/hypr/hyprland.lua`, include the default Nix profile in both PATH and XDG data dirs:

```lua
local nixProfile  = "/nix/var/nix/profiles/default"
local nixBin      = nixProfile .. "/bin"

hl.env("PATH", hmBin .. ":" .. nixBin .. ":/usr/local/bin:/usr/bin:/bin")
hl.env("XDG_DATA_DIRS", hmProfile .. "/share:" .. nixProfile .. "/share:/usr/local/share:/usr/share")
```

2. In `configs/zsh/zshenv`, harden Nix initialization: if `/nix/var/nix/profiles/default/bin/nix` exists but the default profile bin is absent from PATH, unset `__ETC_PROFILE_NIX_SOURCED` before sourcing Nix profile scripts. Optionally add a final direct PATH fallback for the default profile bin.

3. If Home Manager eval fails on a stale Hermes extra such as `pty`, fix `nix/modules/hermes.nix` by removing that extra rather than updating unrelated lockfile inputs. A broad `flake.lock` update can mask the real fix and should be restored unless explicitly requested.

## Verification

Use cheap checks before committing:

```bash
zsh -n configs/zsh/zshenv
luac -p configs/hypr/hyprland.lua  # or lua -e 'assert(loadfile("configs/hypr/hyprland.lua"))'
nix-instantiate --parse configs/hermes/default/config.nix
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
```

Reproduce the hostile inherited-shell case:

```bash
env \
  HOME="$HOME" USER="$USER" SHELL=/bin/zsh \
  PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:/usr/local/bin:/usr/bin:/bin" \
  __ETC_PROFILE_NIX_SOURCED=1 \
  zsh -c 'command -v nix && nix --version'
```

For live Hyprland child-process verification on Hyprland 0.55+ Lua-parser sessions, do not use legacy `hyprctl dispatch exec ...`; it can parse as Lua and fail. Use a small script and Lua dispatcher form:

```bash
cat >/tmp/hypr-nix-path-test.sh <<'EOF'
#!/bin/sh
{
  printf 'PATH=%s\n' "$PATH"
  command -v nix
  nix --version
} >/tmp/hypr-nix-path-test 2>&1
EOF
chmod +x /tmp/hypr-nix-path-test.sh
hyprctl dispatch 'hl.dsp.exec_cmd("/tmp/hypr-nix-path-test.sh")'
sed -n '1,20p' /tmp/hypr-nix-path-test
```

## Commit hygiene

- Stage only intended fix files.
- If evaluation caused an incidental `flake.lock` update, inspect it and restore it unless the user requested lock updates.
- When a verification failure exposes a directly related stale config entry, include that minimal fix in the same commit only if it is required for the requested change to evaluate.
