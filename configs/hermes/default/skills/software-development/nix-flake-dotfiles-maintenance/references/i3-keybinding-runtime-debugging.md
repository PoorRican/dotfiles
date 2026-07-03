# i3 Keybinding Runtime Debugging Notes

Use this when a Home Manager-managed i3 config appears active but a specific shortcut does not fire.

## Proven diagnostic sequence

1. **Separate command failure from keybinding failure**
   - Confirm the live config contains the intended binding:
     ```bash
     i3-msg -t get_config | grep -nE 'set \$launcher|bind(sym|code).*space|Shift\+r'
     ```
   - Run the command through i3, not just from the shell:
     ```bash
     i3-msg 'exec --no-startup-id /path/to/rofi -show combi -show-icons'
     ```
   - If this opens the app, the command and i3 exec path are good; debug the key chord/grab next.

2. **Verify the Home Manager symlink is truly active**
   - Home Manager config files are store symlinks, so compare repo and active target:
     ```bash
     readlink ~/.config/i3/config
     readlink -f ~/.config/i3/config
     cmp -s /home/swe/dotfiles/configs/i3/config ~/.config/i3/config && echo identical || echo DIFFERENT
     ```
   - Do not report a binding as live until the active symlink target matches the repo config and `i3-msg reload` has succeeded.

3. **Check layout/modifier state before changing bindings**
   ```bash
   setxkbmap -query
   xmodmap -pm
   xmodmap -pke | grep -E '= space|= Super|keycode +(65|133|134|206)\b'
   ```

4. **Use bindcode for stubborn physical-key chords**
   - On X11/i3, a symbolic `bindsym $mod+space ...` can fail to fire even when `space` exists in the keymap and the target command works.
   - If the intent is the physical Space key, bind the keycode directly:
     ```i3
     # Space is usually keycode 65 on X11; verify with xmodmap first.
     bindcode $mod+65 exec --no-startup-id $launcher
     ```
   - Keep related symbolic bindings such as `$mod+Shift+space` only if they continue to work; avoid broad rewrites.

5. **Respect muscle-memory corrections**
   - If the user says `Super+Shift+r` is their expected reload chord, preserve that as `reload` and move true `restart` to a less accidental chord such as `Super+Ctrl+Shift+r`.
   - When the user asks whether they need to reset, prefer `i3-msg mode default`, `i3-msg reload`, or `i3-msg restart` before suggesting a reboot/session reset.

## Pitfalls

- `i3-msg -t get_bindings` is not available on all i3 versions; `Unknown message type` is not evidence that bindings are absent. Use `i3-msg -t get_config` plus targeted smoke tests instead.
- Synthetic `xdotool` events may not prove i3 bindings work; some grabs ignore synthetic events. Treat them as weak evidence only.
- A direct shell invocation of an app is insufficient; use `i3-msg exec ...` to verify the same launch path i3 bindings use.
