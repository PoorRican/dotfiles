# cbox Hyprland Special-Workspace Launchers

Session-derived pattern for adding a persistent scratchpad-style launcher in the user's dotfiles-managed Hyprland setup.

## Use case

Create a drun/menu entry and hotkeys that open a dedicated terminal workspace, keep it available across regular workspaces, and hide/show it without destroying state. Example: a Project Kairos wiki terminal that opens Ghostty, changes to the wiki directory, and attaches/creates a named Zellij session with a fixed layout.

## Durable pattern

1. **Put the launcher logic in a repo script** under `bin/<name>` and deploy it with Home Manager:

   ```nix
   home.file.".local/bin/<name>" = {
     source = dotfiles + "/bin/<name>";
     executable = true;
   };
   ```

2. **Give the terminal a unique app class/title** so Hyprland can find it reliably:

   ```bash
   ghostty \
     --class=com.example.scratchpad \
     --title=example-scratchpad \
     --gtk-single-instance=false \
     --working-directory="$target_dir" \
     -e "$HOME/.local/bin/<name>" --inside-terminal
   ```

   `--gtk-single-instance=false` matters for a dedicated Ghostty instance with a distinct Wayland app id/class.

3. **Use a named special workspace for scratchpad behavior**. In Hyprland 0.55+ with the Lua parser, legacy hyprctl syntax can fail for dispatchers from shell scripts. Prefer Lua dispatcher forms:

   ```bash
   hyprctl dispatch 'hl.dsp.workspace.toggle_special("my-scratchpad")'
   hyprctl dispatch 'hl.dsp.exec_cmd("[workspace special:my-scratchpad; float; size 85% 85%; center] /path/to/command")'
   ```

   Avoid assuming this legacy form works in Lua-parser sessions:

   ```bash
   hyprctl dispatch togglespecialworkspace my-scratchpad
   hyprctl dispatch exec '[workspace special:my-scratchpad] ...'
   ```

4. **Add a drun entry via Home Manager** so Rofi can launch it:

   ```nix
   xdg.dataFile."applications/example-scratchpad.desktop".text = ''
     [Desktop Entry]
     Type=Application
     Name=Example Scratchpad
     Comment=Open the example scratchpad
     Exec=${config.home.homeDirectory}/.local/bin/<name> --toggle
     Terminal=false
     Categories=Utility;
     StartupWMClass=com.example.scratchpad
     Keywords=Scratchpad;Terminal;
   '';
   ```

   Keep `Categories` to one main category such as `Utility;` to avoid desktop-file-validator duplicate-menu hints.

5. **Add Hyprland binds and a window rule** in `configs/hypr/hyprland.lua`:

   ```lua
   local scratchpad = home .. "/.local/bin/<name>"
   hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(scratchpad .. " --toggle"))
   hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scratchpad .. " --hide"))

   hl.window_rule({
       name  = "example-scratchpad-terminal",
       match = { class = "^com\\.example\\.scratchpad$" },
       float  = true,
       size   = "85% 85%",
       center = true,
   })
   ```

   After `home-manager switch`, verify live binds with `hyprctl -j binds`; if Lua reload does not show new binds, apply them temporarily with `hyprctl eval ...` or restart Hyprland.

## Zellij layout/session notes

For a named Zellij session that should be created with a specific layout and attached later:

```bash
if zellij list-sessions --short --no-formatting | awk '$0 == "session-name" { found = 1 } END { exit found ? 0 : 1 }'; then
  exec zellij attach --force-run-commands session-name
fi

exec zellij --session session-name --new-session-with-layout layout-name
```

Do not use `zellij --session session-name --layout layout-name` as the create path in this setup; it can report the session is not found instead of creating it. `--new-session-with-layout` is the explicit creation flag.

## Verification checklist

- `bash -n bin/<name>`
- `luac -p configs/hypr/hyprland.lua`
- `zellij setup --dump-layout <layout-name>`
- `desktop-file-validate` on the generated desktop entry text
- `home-manager build --flake .#cbox --no-write-lock-file`
- `home-manager switch --flake .#cbox --no-write-lock-file`
- `readlink -f ~/.local/bin/<name>` and `~/.local/share/applications/<entry>.desktop`
- `hyprctl reload` then `hyprctl -j binds` for the hotkeys
- run `<name> --toggle`; check `hyprctl -j clients` for the unique class and `zellij list-sessions --short --no-formatting` for the named session

## Pitfalls

- Home Manager flake evaluation needs newly imported files staged before build/eval if the repo is dirty.
- If `nix` is installed outside the visible PATH, prepend the live Nix profile path for Home Manager commands, e.g. `PATH=/nix/var/nix/profiles/default/bin:$PATH home-manager ...`; capture this as a live environment fix, not a durable claim that Nix is absent.
- Special workspaces are better for sticky scratchpads than trying to make one floating client follow every workspace manually.
- Fullscreen visibility is compositor-sensitive: named special workspace plus floating window is the intended path, but verify with an actual fullscreen client after applying/reloading.
- In Hyprland 0.55 Lua-parser sessions, inline exec rules like `[float; pin; size 85% 85%; center] ...` may float/pin/center but ignore percentage `size`. For reliable first-launch geometry, wait for the client, compute 85% of the focused monitor from `hyprctl -j monitors`, then call Lua dispatchers with exact pixels: `hl.dsp.window.resize({ x = W, y = H, exact = true })` and `hl.dsp.window.move({ x = X, y = Y, exact = true })`. Preserve user adjustments by saving/restoring geometry after the first placement.
