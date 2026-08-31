# cbox Hyprland Rofi symbol picker

Use this note when the user wants the old i3 Rofi symbol picker available in Wayland/Hyprland, especially for mathematical symbols.

## Durable pattern

- Keep the symbol catalog as a managed TSV at `configs/rofi/symbols.tsv` and expose it through `xdg.configFile."rofi/symbols.tsv"`.
- Prefer a small Wayland-native shell helper such as `bin/hypr-symbol-picker`:
  - prepend the Home Manager profile bin path so keybind execution has `rofi`, `wl-copy`, `wtype`, and `notify-send` available;
  - read `~/.config/rofi/symbols.tsv` with `awk -F '\t'` and feed it to `rofi -dmenu -i`;
  - extract the first tab-separated field as the glyph;
  - copy with `wl-copy --type text/plain`;
  - after a short delay, paste with `wtype -M ctrl v -m ctrl`.
- Do not make notifications a hard dependency. A picker should still copy/paste when `notify-send` or the notification daemon is broken.
- If the request says “mathematical symbols,” keep the primary list math-focused: logic, sets, number sets, relations, operators, calculus, arrows, Greek letters, geometry, and common superscripts/subscripts. Do not mix the entire emoji DB into the primary result set unless the user asks for emoji too.

## Home Manager wiring

In `nix/modules/hyprland-desktop.nix`:

```nix
home.packages = with pkgs; [
  rofi
  wl-clipboard
  wtype
  # rofi-emoji optional if a separate emoji mode is still desired
];

home.file.".local/bin/hypr-symbol-picker" = {
  source = dotfiles + "/bin/hypr-symbol-picker";
  executable = true;
};

xdg.configFile."rofi/symbols.tsv".source = lib.mkDefault (dotfiles + "/configs/rofi/symbols.tsv");
```

In `configs/hypr/hyprland.lua`, define a local script path near the other program variables and bind it with the same muscle memory as i3:

```lua
local symbolMenu = home .. "/.local/bin/hypr-symbol-picker"
hl.bind(mainMod .. " + CTRL + Space", hl.dsp.exec_cmd(symbolMenu))
```

## Verification

- `bash -n bin/hypr-symbol-picker`
- Lua parse check if `luac` is available: `luac -p configs/hypr/hyprland.lua`
- `nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file`
- `home-manager switch --flake .#cbox`
- Confirm installed links and tools:
  - `readlink -f ~/.local/bin/hypr-symbol-picker`
  - `readlink -f ~/.config/rofi/symbols.tsv`
  - `command -v rofi wl-copy wtype`
- Validate the TSV shape with a quick parser: every non-empty row should have at least two tab-separated fields; duplicate glyphs are usually accidental.

## Pitfalls

- `hyprctl reload` does NOT re-execute a Lua config file on Hyprland 0.55 — `hl.bind()` calls from `hyprland.lua` only register at compositor startup. To make a new Lua bind live without a logout: `hyprctl eval 'hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("/path/to/script"))'` (plain `hyprctl keyword bind ...` is rejected with "keyword can't work with non-legacy parsers. Use eval.", and `hyprctl bind` returns "unknown request" — the Lua dispatcher is the only path).
- Verify a live bind with `hyprctl -j binds` and matching on `modmask` (SUPER=64, CTRL=4 → 68) and `key`; Lua binds show `dispatcher: __lua` with an opaque `arg` number, so never grep for the command path.
- `wtype` modifier syntax for paste is `wtype -M ctrl v -m ctrl`; do not port X11 `xdotool key --clearmodifiers ctrl+v`, and do not invent unsupported `-k` syntax.
- A script that calls `notify-send` unconditionally can appear broken while notification debugging is still unresolved. Treat notifications as best-effort for this picker.
- Installing packages is not the same as deploying the helper script. Confirm the Home Manager symlink under `~/.local/bin` after `home-manager switch`.
- Hyprland Lua config may be correct on disk but not picked up by the running compositor until reload/restart. Distinguish repo state, applied Home Manager state, and live bind state in status reports.
