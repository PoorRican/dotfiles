# cbox Hyprland Wayland clipboard pattern

Session context: Ghostty was running as a native Wayland client under Hyprland (`xwayland=false`). The existing clipboard UX came from the i3/X11 setup (`clipmenu`, `xclip`, `xdotool`), so it did not fully work for Ghostty or other native Wayland apps.

## Diagnosis checklist

- Confirm session/client shape:
  - `echo "$XDG_SESSION_TYPE $WAYLAND_DISPLAY $DISPLAY"`
  - `hyprctl clients -j | jq '.[] | select(.class|test("ghostty"; "i")) | {class,initialClass,title,xwayland,pid}'`
- Confirm basic Wayland clipboard works before changing config:
  - Save/restore current clipboard if probing live.
  - `printf probe | wl-copy --type text/plain`; `wl-paste --no-newline` should return the probe.
- Check whether a history collector is running:
  - `ps -u "$USER" -o pid,comm,args | grep -E 'wl-paste|cliphist|clipmenud|xclip|xsel'`

## Durable fix shape

For Hyprland/Ghostty, use native Wayland clipboard tools rather than the i3/X11 path:

1. Install `wl-clipboard`, `cliphist`, and `wtype` in the Hyprland Home Manager module.
2. Add a startup helper that idempotently starts collectors:
   - `wl-paste --type text --watch cliphist store`
   - optionally `wl-paste --type image --watch cliphist store`
3. Start that helper from Hyprland startup (`hl.on("hyprland.start", ...)`) after Wayland/session environment is available.
4. Add a clipboard menu script:
   - `cliphist list | rofi -dmenu -i -p clipboard`
   - pipe selection through `cliphist decode | wl-copy`
   - inject paste into the focused client with `wtype -M ctrl -k v -m ctrl` after a short delay.
5. Add a Wayland symbol/emoji picker that writes selected text with `wl-copy` and uses the same `wtype` paste injection.
6. Bind Hyprland keys such as `Super+Ctrl+V` for history and `Super+Ctrl+Space` for symbols.

## Pitfalls

- `cliphist` being installed is not enough; it needs a live `wl-paste --watch ... cliphist store` process.
- X11 tools (`clipmenu`, `xclip`, `xdotool`) may still work in XWayland clients but are the wrong default for native Wayland Ghostty.
- `wtype` may not be installed even when `wl-copy` and `cliphist` are present; add it to the Hyprland package set for paste injection.
- Live clipboard probes modify user clipboard state. Save the current clipboard type/content to a temp file and restore it, and get explicit approval before destructive clipboard probing if the tool layer requires it.
- If adding new scripts imported by a flake/Home Manager module, stage the new script files before `nix eval`, otherwise flake evaluation can miss untracked files.

## Verification

- `bash -n` for helper scripts.
- `luac -p configs/hypr/hyprland.lua` if `luac` is available.
- `nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file` with the correct `nix` binary/path.
- Runtime: run the start helper, verify `wl-paste --watch cliphist store` processes exist, copy a probe via `wl-copy`, and confirm the top `cliphist list | cliphist decode` entry matches before restoring clipboard.
