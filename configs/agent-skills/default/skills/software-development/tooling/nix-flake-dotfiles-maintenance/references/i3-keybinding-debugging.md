# i3 Keybinding Debugging Notes

Use this when an i3 binding appears active in the config but pressing the keys does nothing.

## Durable lessons

### i3 `set` expansion is not recursive

i3 expands variables in commands, but a variable value that itself contains another variable may remain literal when expanded later. Avoid patterns like:

```i3
set $hm_bin /home/swe/.local/state/nix/profiles/home-manager/home-path/bin
set $launcher $hm_bin/rofi -show combi -show-icons
bindsym $mod+space exec --no-startup-id $launcher
```

A binding event may then show i3 running the literal command:

```text
exec --no-startup-id $hm_bin/rofi -show combi -show-icons
```

Prefer fully-expanded command variables when the value will be used as a command:

```i3
set $launcher /home/swe/.local/state/nix/profiles/home-manager/home-path/bin/rofi -show combi -show-icons
set $run_launcher /home/swe/.local/state/nix/profiles/home-manager/home-path/bin/rofi -show run
```

Keep helper prefixes (`$hm_bin`, `$local_bin`) for direct command lines where i3 expands them in that same line:

```i3
bindsym $mod+m exec --no-startup-id $hm_bin/polybar-msg cmd toggle
```

### Separate four layers before changing bindings

1. **Command works:** run via `i3-msg 'exec --no-startup-id /absolute/path/to/app ...'`.
2. **X sees the physical chord:** capture with `xinput test-xi2 --root` and inspect keycodes/modifier mask.
3. **i3 fires the binding:** subscribe with `i3-msg -t subscribe -m '["binding"]'` while pressing the chord.
4. **Active Home Manager symlink matches repo:** compare `~/.config/i3/config` to the repo file after `home-manager switch`.

This prevents misdiagnosing a command/path problem as a keyboard problem, or vice versa.

### Useful probes

```bash
# Check physical keys/keycodes/modifiers.
xinput test-xi2 --root
xmodmap -pke | grep -E 'keycode +(65|36|133|134)\b'
xmodmap -pm

# Check whether i3 fires a binding.
i3-msg -t subscribe -m '["binding"]'

# Smoke-test a command through i3 itself.
i3-msg 'exec --no-startup-id /absolute/path/to/rofi -show combi -show-icons'

# Validate applied config and Home Manager link.
i3 -C -c /home/swe/dotfiles/configs/i3/config
home-manager switch --flake .#cbox
i3-msg reload
cmp -s /home/swe/dotfiles/configs/i3/config ~/.config/i3/config && echo identical
```

### cbox/Kinesis detail

On cbox/i3, the Kinesis Adv360 Pro Command key arrives as Super/Mod4 (`Super_L`/`Super_R`). Space is keycode 65 in the observed X11 mapping. If `bindsym $mod+space` is unreliable, `bindcode $mod+65` is an acceptable fallback after confirming the keycode with `xinput`/`xmodmap`.
