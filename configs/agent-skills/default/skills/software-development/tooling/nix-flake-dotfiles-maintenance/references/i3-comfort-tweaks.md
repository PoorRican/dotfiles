# i3 comfort tweaks for macOS-to-Linux transition

Use this note when continuing the cbox/i3 desktop setup after the legacy i3 config has been ported into Home Manager.

## Workflow lessons

- If the user says to commit the i3 work so far before more tweaks, commit the staged i3/Home Manager files first, then make the next round as a separate unstaged/staged diff.
- The user may have an existing Ghostty installation/config. Do not import `nix/modules/ghostty.nix` into `nix/modules/i3-desktop.nix` just to make i3 launch Ghostty; that can make Home Manager try to clobber `~/.config/ghostty/config`. Prefer calling the existing `ghostty` binary from i3 and only manage Ghostty config when explicitly requested.
- For nixpkgs 26.05, prefer top-level `pkgs.xinput` rather than deprecated `pkgs.xorg.xinput`.

## Natural scrolling under i3/X11

For macOS-style global natural scrolling on X11/i3, use an idempotent startup script that applies libinput's natural scrolling property to every XInput device exposing it:

```bash
while IFS= read -r id; do
  props="$(xinput list-props "$id" 2>/dev/null || true)"
  prop_id="$(printf '%s\n' "$props" | awk -F'[()]' '/libinput Natural Scrolling Enabled \(/ { print $2; exit }')"
  if [ -n "$prop_id" ]; then
    xinput set-prop "$id" "$prop_id" 1 >/dev/null 2>&1 || true
  fi
done < <(xinput list --id-only 2>/dev/null || true)
```

Run it from i3 with `exec_always --no-startup-id i3-natural-scroll` so reloads/hotplug recovery reapply the setting.

## Rofi setup patterns

For a Spotlight-like launcher:

```rasi
modi: "combi,drun,run,window,ssh";
combi-modi: "drun,run,window,ssh";
terminal: "ghostty";
matching: "fuzzy";
sorting-method: "fzf";
```

Bind `Super+Space` to `rofi -show combi -show-icons`. Rofi `window` mode is useful for search/select but does not behave like macOS Cmd+Tab repeated cycling, so avoid replacing `Super+Tab` unless the user explicitly accepts that behavior.

## Clipboard, symbols, and cheat sheet

Useful cbox/i3 comfort packages:

```nix
clipmenu
rofi-emoji
xclip
xdotool
xinput
```

Patterns:
- Start `clipmenud` once per i3 session; it only remembers clips copied after it starts.
- A clipboard picker can use `CM_LAUNCHER=rofi CM_OUTPUT_CLIP=1 clipmenu -dmenu -i -p clipboard`, copy the result with `xclip -selection clipboard`, then optionally paste using `xdotool key --clearmodifiers ctrl+v`.
- For emoji/symbol picking, combine `rofi-emoji`'s `all_emojis.txt` with a dotfiles-managed `configs/rofi/symbols.tsv` containing math/logical/keyboard symbols such as `∴`, `∵`, `⇒`, `λ`, `π`, `⌘`, `⌥`, etc.
- An i3 keybinding cheat sheet can parse `bindsym` lines from the live i3 config and feed them to `rofi -dmenu`; selecting a row copies it with `xclip`.

## Vivaldi and Quake terminal patterns

Vivaldi comfort launcher:

```bash
i3-msg '[class="Vivaldi"] focus' >/dev/null 2>&1 || exec vivaldi-stable
```

Dedicated Ghostty scratch terminal pattern:
- Remove generic scratchpad keybindings if the user wants only a Quake terminal exposed.
- Launch Ghostty with a distinct class/title, e.g. `ghostty --class=ghostty-quake --x11-instance-name=ghostty-quake --title="Quake Terminal"`.
- Add an i3 rule for that class to float/stick/resize/move to scratchpad.
- Toggle with a script that first tries `i3-msg '[class="ghostty-quake"] scratchpad show'`; if no window matches, launch Ghostty and retry briefly.

## Runtime PATH pitfall

A running i3 process can inherit a minimal login/session `PATH` that does **not** include Home Manager's `home-path/bin` or `~/.local/bin`, even after `home-manager switch`. In that state, the live config can contain new bindings but `exec rofi`, `exec i3-vivaldi`, `exec i3-quake-terminal`, etc. silently fail from keybindings.

For cbox/i3 comfort bindings, prefer one or both of:

```i3
set $hm_bin /home/swe/.local/state/nix/profiles/home-manager/home-path/bin
set $local_bin /home/swe/.local/bin
set $launcher $hm_bin/rofi -show combi -show-icons
bindsym $mod+space exec --no-startup-id $launcher
bindsym $mod+grave exec --no-startup-id $local_bin/i3-quake-terminal
```

And add this near the top of helper scripts launched by i3:

```bash
export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.local/bin:$PATH"
```

Verification clue: `i3-msg -t get_config` may show the new binding while pressing the key does nothing; inspect `/proc/$(pgrep -u "$USER" -x i3 | head -n1)/environ` to see the inherited PATH.

## Verification

After changes:

```bash
bash -n bin/i3-*
i3 -C -c /home/swe/dotfiles/configs/i3/config
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
home-manager switch --flake .#cbox
i3-msg reload
```

Then verify live links and behavior:

```bash
cmp -s ~/.config/i3/config /home/swe/dotfiles/configs/i3/config
cmp -s ~/.config/rofi/config.rasi /home/swe/dotfiles/configs/rofi/config.rasi
pgrep -a -u "$USER" clipmenud
xinput list-props <mouse-id> | grep 'Natural Scrolling Enabled'
```
