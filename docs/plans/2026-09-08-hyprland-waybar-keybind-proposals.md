# Hyprland Waybar and Keybind Proposals

## Objective

Give the cbox Hyprland desktop a deliberate Waybar identity and adopt the
keybind ideas from other Hyprland setups that are genuinely new to this
configuration. Two visual directions are proposed: a compositor-heavy
glass bar and a clean 16-bit/CLI bar. The keybind proposals are independent
of the visual direction.

This document is a menu. Nothing in it is implemented. Tick the items you
want; anything unticked is dropped.

## How to review

- `[ ]` items are proposals. Mark `[x]` to accept.
- Every claim about the local machine is marked **proven** (observed at
  runtime on cbox, 2026-09-04/08) or **inferred** (from source code or
  documentation, not executed here).
- Chords were checked against every bind in `configs/hypr/hyprland.lua`
  lines 348-443 and the two runtime binds installed by `bin/pk-wiki`
  (`SUPER+grave`, `SUPER+SHIFT+grave`). Section 5 lists every reserved
  chord so alternatives can be chosen without re-reading the config.
- Sources are listed in section 7 and linked inline the first time they
  are cited.

## 1. Verified environment

| Fact | Value | Status |
| --- | --- | --- |
| Waybar | 0.15.0-3 (Arch package), GTK 3 (`libgtk-3.so.0`, `libgtk-layer-shell`) | proven |
| Native modules that instantiate cleanly | `mpris`, `privacy`, `wireplumber`, `upower`, `power-profiles-daemon`, `systemd-failed-units`, `gamemode`, `image`, `hyprland/language`, `hyprland/window`, `hyprland/submap`, `hyprland/workspaces`, `group` with `drawer` | proven |
| `cava` | **Unknown module** (`Disabling module "cava"`); script route only | proven |
| `temperature` | Compiled in; disabled by default config because there is no `/sys/class/thermal/thermal_zone0`. Needs an explicit hwmon path (see 3.4) | proven |
| `keyboard-state` | Compiled in; disabled with `EACCES` because `swe` is not in the `input` group (`id -nG` = `swe autologin ollama docker wheel`) | proven |
| Notification daemon | dunst (`services.dunst.enable = true` in `nix/modules/hyprland-desktop.nix`) | proven |
| GPUs | `01:00.0` NVIDIA AD102 RTX 4070 Ti SUPER (dGPU, `nvidia-smi` works: 39 C idle); `74:00.0` AMD Granite Ridge Radeon (Ryzen iGPU, hwmon `amdgpu`) | proven |
| CPU sensor | `k10temp`, stable device path `/sys/devices/pci0000:00/0000:00:18.3`, `temp1_input` = Tctl | proven |
| Board sensor | `nct6687`, stable device path `/sys/devices/platform/nct6683.2592` | proven |
| Waybar blur | No `hl.layer_rule` for Waybar exists in `hyprland.lua`; the 0.72-alpha islands are translucent, not blurred | proven |
| Hyprland blur | `decoration.blur = { size = 3, passes = 1, vibrancy = 0.1696 }` | proven |
| Existing `custom/ws1..10` modules | Required: Waybar's built-in `hyprland/workspaces` click path sends a legacy dispatch that the Lua config parser rejects (`config.jsonc:50`). Display works, clicks do not | proven (comment in repo) |

## 2. Prerequisite for either direction

- [ ] **2.1 Blur layer rule for Waybar** (`configs/hypr/hyprland.lua`, next to the
  commented layer-rule example at line 497).

  ```lua
  hl.layer_rule({
      name         = "waybar-glass",
      match        = { namespace = "^waybar$" },
      blur         = true,
      ignore_alpha = 0.3,   -- keep the transparent gaps between islands sharp
  })
  ```

  `ignore_alpha` is what stops the blur from smearing the fully transparent
  `window#waybar` background between the three island groups. HyDE ships the
  same pair of rules (`blur` plus a separate `ignore_alpha`) in
  [`layer_rules.lua`](https://raw.githubusercontent.com/HyDE-Project/HyDE/master/Configs/.local/share/hypr/lua/layer_rules.lua).
  Syntax and effect names are from the
  [layer-rules wiki](https://wiki.hypr.land/configuring/core/rules/layer-rules/)
  (`blur`, `blur_popups`, `ignore_alpha`, `xray`, `no_anim`, `order`).
  Even the CLI direction benefits: a blurred near-opaque strip reads as a
  real terminal, not a stripe painted on the wallpaper.

- [ ] **2.2 Blur popups too**: add `blur_popups = true` so the clock calendar
  and tooltips match the bar. inferred from the wiki table; not yet tested.

- [ ] **2.3 Apply the same rule to rofi and dunst** (`namespace = "^rofi$"`,
  `"^notifications$"`) for a consistent overlay language. inferred.

## 3. Waybar direction

Pick **one** of 3.1 or 3.2. Items in 3.3-3.5 apply to whichever is chosen.

### 3.1 Direction A: compositor glass (macOS-like)

Reference bars, all inspected by screenshot and config, not README only:

| Bar | What to borrow |
| --- | --- |
| [sejjy/mechabar](https://github.com/sejjy/mechabar) (865 stars) | Chevron-cut segments with a raised centre "notch"; modular per-module `.jsonc` files; Catppuccin. Closest to a Dynamic-Island bar in pure Waybar CSS. |
| [HANCORE V2.7b](https://github.com/HANCORE-linux/waybar-themes#v27b) | Right-side stats collapse into a click-expandable drawer (`group` + `drawer`). Light "paper" palette variant. |
| [HANCORE V1.6](https://github.com/HANCORE-linux/waybar-themes#v16) | Full-width hairline bar with circular CPU/RAM gauges drawn with `nf-md-circle_slice_N` glyphs; no scripts. |
| [atif V4](https://github.com/atif-1402/minimal-waybar-themes#v4) | end-4 style pill bar: app icon plus name at left, mpris pill, dot workspaces, centred clock, cava strip. |
| [rose-pine/waybar](https://github.com/rose-pine/waybar), [catppuccin/waybar](https://github.com/catppuccin/waybar) | Official palette CSS via `@import`. |

Proposals:

- [ ] **A1 Geometry**: keep three floating islands (current), raise
  `border-radius` to 18-20 px, replace the 1 px white border with a 1 px
  `alpha(fg, 0.10)` top-only highlight and `box-shadow: 0 10px 30px
  rgba(0,0,0,0.45)` for the lifted-glass look. Height stays 34.
- [ ] **A2 Hyprland blur strength**: `size = 6`, `passes = 2`, keep
  `vibrancy`. At the current `3/1` the bar reads "slightly out of focus"
  rather than frosted. inferred; needs a live A/B.
- [ ] **A3 Stats drawer**: wrap `cpu`, `memory`, `disk`, `network`,
  `bluetooth`, `idle_inhibitor` in a `group/stats` with
  `"drawer": { "transition-duration": 400 }` so the right island is a single
  glyph until hovered/clicked. Pattern from atif V3.Omega-x config (read) and
  HANCORE V2.7b (screenshot).
- [ ] **A4 Now-playing pill**: native `mpris` module,
  `"format": "{player_icon} {dynamic}"`, `"dynamic-len": 40`, hidden when
  no player. proven available.
- [ ] **A5 Privacy dot**: native `privacy` module (mic / screen-share
  indicator, the macOS orange dot). proven available.
- [ ] **A6 Circular gauges**: render `cpu` and `memory` with
  `format-icons` over `nf-md-circle_slice_1..8` instead of `{usage}%`. No
  script; from HANCORE V1.6.
- [ ] **A7 Palette**: adopt Rose Pine (moody, matches the existing
  `#bb9af7`/`#7aa2f7` leanings) or Catppuccin Mocha via `@import`.
  Choose: `[ ] rose-pine  [ ] catppuccin-mocha  [ ] keep current defines`.
- [ ] **A8 Workspace dots**: restyle `custom/ws1..10` as 6 px dots that
  widen into a 18 px pill when active (`transition` on `min-width` and
  `padding`). Keeps the Lua-dispatch click path.
- [ ] **A9 Centre notch**: mechabar's raised centre segment holding the
  active-window title, cut with negative margins and a contrasting
  background. Purely cosmetic; skip if A1 is enough.

Known ceiling: GTK 3 has no `backdrop-filter`, so edge-refraction "liquid
glass" is not reachable in Waybar (thread:
[Liquid glass effect on Waybar](https://www.reddit.com/r/hyprland/comments/1mwkbtd/liquid_glass_effect_on_waybar/)).
Compositor blur plus inset highlights is the limit. proven (GTK 3 link).

### 3.2 Direction B: 16-bit / CLI

Reference bars:

| Bar | What to borrow |
| --- | --- |
| [atif V3.Omega-x](https://github.com/atif-1402/minimal-waybar-themes#v3%CF%89x) | Right side is literal text: `[BTMBAR][UP 0h 57m][VOL 80%][05:54 AM]`. Config read: `"format": "[VOL {volume}%]"`, `"[{:%I:%M %p}]"`. Scroll-on-stats cycles CPU/MEM/SWAP. Optional bottom bar toggled by a module. |
| [atif V3](https://github.com/atif-1402/minimal-waybar-themes#v3) | Roman-numeral workspaces via `format-icons` (`"1":"I"` ...), underline-on-active, "Game Mode" module that disables blur and animations. |
| [HANCORE V2.9a/b](https://github.com/HANCORE-linux/waybar-themes#v29a) | Text-only modules: `bt on 0 . network on . power balanced . vol 100% . mem 13% . cpu 4%`; lowercase labels, one accent colour, no icons. Reads like a tmux status line. |
| [mechatour/amber_gold.dotfiles](https://github.com/mechatour/amber_gold.dotfiles) | Amber-phosphor palette across Waybar, Emacs and terminal. |

Proposals:

- [ ] **B1 Geometry**: single full-width strip, `height` 22-24,
  `margin` 0, `border-radius` 0, no shadow, 1 px bottom border in the
  accent colour or none. Islands become plain spacing.
- [ ] **B2 Font**: a bitmap/pixel face as primary, JetBrainsMono Nerd Font
  second purely for glyphs. Choose:
  `[ ] Departure Mono  [ ] Terminus (TTF)  [ ] Cozette  [ ] Scientifica
  [ ] Mx437 IBM VGA 8x16`. Needs a font package added to the cbox host
  profile; none of these is currently installed. inferred.
- [ ] **B3 Bracket-text modules**: `"[VOL {volume}%]"`, `"[MEM {}%]"`,
  `"[{:%H:%M}]"`, `"[NET {essid}]"`; icons removed entirely. Right-align
  numbers (`{usage:>2}`) so nothing jitters.
- [ ] **B4 Workspace rendering**: `[1] 2 3 4 5 | 6 7 8 9 0` with the active
  slot in inverse video (`background: @fg; color: @bg`) and occupied slots
  in `@fg`, empty in `@muted`. Keeps `custom/ws*`.
  Alternative: `[ ] roman numerals` (atif V3).
- [ ] **B5 Text gauges**: a 3-line script per gauge producing
  `▁▂▃▄▅▆▇█` sparklines for CPU or `[####....]` for memory, or a single
  scroll-to-cycle stats module as in atif V3.Omega-x.
- [ ] **B6 Submap indicator**: `hyprland/submap` as `-- RESIZE --` in
  inverse video at the far left, vim style.
- [ ] **B7 Palette**: choose `[ ] amber phosphor  [ ] green phosphor
  [ ] monochrome grey on near-black  [ ] Gruvbox hard`.
- [ ] **B8 Optional bottom strip** with the slow-changing stats, toggled by
  a `[BTMBAR]` module (atif V3.Omega-x). Two bars means two Waybar
  configs; the `hypr-waybar` service would need a second instance or a
  multi-bar config array. inferred.

### 3.3 Shared: hide/show and game mode

- [ ] **S1 Toggle bar**: `pkill -SIGUSR1 waybar` toggles visibility
  without killing the service (Waybar behaviour; the systemd unit's
  `Restart=always` is not triggered). Bind proposed in 4.1.
- [ ] **S2 Game mode**: a script that flips `decoration.blur.enabled`,
  `animations.enabled` and `decoration.shadow.enabled` via `hyprctl
  keyword`, with a bar indicator. From atif V3 and JaKooLit
  (`SUPER+SHIFT+G` there). Chord proposed in 4.2.

### 3.4 Shared: sensors (fixes for modules that are compiled in but disabled)

- [ ] **T1 CPU temperature**, using the stable device path rather than
  `hwmonN` (indices are not stable across boots):

  ```jsonc
  "temperature": {
    "hwmon-path-abs": "/sys/devices/pci0000:00/0000:00:18.3/hwmon",
    "input-filename": "temp1_input",
    "critical-threshold": 85,
    "format": "{temperatureC}°"
  }
  ```

  proven path; the `hwmon-path-abs` key is inferred from Waybar docs and
  should be gated with the one-second harness in section 6.
- [ ] **T2 GPU temperature/utilisation**: `custom/gpu` over
  `nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader`
  (proven: returns `39, 0 %`). The NVIDIA card is not in hwmon.
- [ ] **T3 Board temperature**: `hwmon-path-abs` =
  `/sys/devices/platform/nct6683.2592/hwmon`, `temp1_input`. proven path.
- [ ] **T4 Caps/Num indicator** (`keyboard-state`): requires
  `sudo usermod -aG input swe` and re-login. Extra privilege for a
  cosmetic; recommended only for direction B.

### 3.5 Shared: cava visualiser

- [ ] **V1** `custom/cava` running `cava` with `[output] method = raw`,
  mapping 0-7 to `▁▂▃▄▅▆▇█`. `cava` is not a native module on this build
  (proven). Requires the `cava` package. Fits A (as a pill) and B (as a
  strip).

## 4. Keybind proposals

All chords below are **free** against the reserved table in section 5
unless a note says otherwise. Lua shapes follow the existing file style
(`hl.bind(mainMod .. " + KEY", dispatcher, { flags })`).

### 4.1 Tier 1: new here, portable, high value

- [ ] **K1 Compositor zoom** on `SUPER+Minus` / `SUPER+Equal`,
  `repeating = true`, clamped 1.0-3.0. From
  [end-4 `keybinds.lua`](https://raw.githubusercontent.com/end-4/dots-hyprland/main/dots/.config/hypr/hyprland/keybinds.lua)
  (`zoomfunction`); also JaKooLit (`SUPER+ALT+scroll`) and the top reply in
  the r/hyprland keybind-favourites thread.

  ```lua
  local function zoomBy(delta)
      local z = hl.get_config("cursor:zoom_factor") + delta
      hl.config({ cursor = { zoom_factor = math.max(1.0, math.min(3.0, z)) } })
  end
  hl.bind(mainMod .. " + Minus", function() zoomBy(-0.3) end, { repeating = true })
  hl.bind(mainMod .. " + Equal", function() zoomBy(0.3) end,  { repeating = true })
  hl.bind(mainMod .. " + CTRL + Equal", function()
      hl.config({ cursor = { zoom_factor = 1.0 } }) end)
  ```

- [ ] **K2 Tap-Super opens the launcher**: `hl.bind("SUPER + SUPER_L",
  hl.dsp.exec_cmd(menu), { release = true })`. Super held with another key
  still works. From end-4. `SUPER+Space`/`SUPER+R` remain as fallbacks or
  can be freed.
- [ ] **K3 Notification chord** (dunst, not mako as previously stated):
  `SUPER+N` = `dunstctl close`, `SUPER+SHIFT+N` = `dunstctl close-all`,
  `SUPER+CTRL+N` = `dunstctl set-paused toggle`, `SUPER+ALT+N` =
  `dunstctl context` (invoke action), `SUPER+SHIFT+ALT+N` =
  `dunstctl history-pop`. Omarchy's layout
  ([utilities.conf](https://raw.githubusercontent.com/basecamp/omarchy/master/default/hypr/bindings/utilities.conf))
  uses `SUPER+Comma`, which is **taken** here by the scrolling-layout
  `move -col`; `N` is free.
- [ ] **K4 Bar-less info popups**: `SUPER+CTRL+ALT+T` =
  `notify-send -u low "$(date +'%A %H:%M · %d %B %Y · Week %V')"`. Pairs with
  S1 for a hidden bar. From Omarchy.
- [ ] **K5 Focus-mode toggles**: `SUPER+SHIFT+Space` = toggle bar (S1);
  `SUPER+SHIFT+Backspace` = toggle gaps (set `gaps_in/out` 0 or restore);
  `SUPER+Backspace` = toggle active-window opacity. From Omarchy.
- [ ] **K6 Silent move to workspace**: `SUPER+CTRL+<digit>` =
  `hl.dsp.window.move({ workspace = i, follow = false })`. JaKooLit uses
  this chord; HyDE and postsolar use `SUPER+ALT`, which K8 takes.
- [ ] **K7 Previous workspace / nearest empty**: `SUPER+CTRL+Tab` =
  `hl.dsp.focus({ workspace = "previous" })`; `SUPER+ALT+E` =
  `hl.dsp.focus({ workspace = "empty" })`. HyDE binds empty to
  `SUPER+CTRL+Down`, which is **taken** here by resize.
- [ ] **K8 Group by number**: `SUPER+ALT+<1..5>` =
  `hl.dsp.group.set_active({ index = n })` (Omarchy `changegroupactive N`).
  Complements the existing group binds. The exact Lua dispatcher name for
  `changegroupactive N` is **inferred**; verify against `hl.dsp.group` in
  the Hyprland Lua reference before use.
- [ ] **K9 Tiled fullscreen spoof**: `SUPER+CTRL+F` =
  `hl.dsp.window.fullscreen_state({ internal = 0, client = 3, action = "toggle" })`.
  The app believes it is fullscreen (hides its chrome) but stays tiled.
  From end-4 (`SUPER+ALT+F`) and Omarchy (`fullscreenstate 0 2`).
  Alternative: replace `SUPER+F` with HyDE's `cycle_fullscreen` (0 -> 1 -> 2
  -> 0 using `hl.get_active_window().fullscreen`) so one key covers all
  three states. Choose: `[ ] separate chord  [ ] cycle on SUPER+F`.
- [ ] **K10 Left-drag resize**: `SUPER+CTRL+mouse:272` =
  `hl.dsp.window.resize()`, `{ mouse = true }`. Touchpad-friendly; the most
  upvoted reply in the favourites thread.

### 4.2 Tier 2: clever, worth a look

- [ ] **K11 Launch-or-focus** for `SUPER+B` (browser): if a window with
  class matching Vivaldi exists, focus it, else launch. Omarchy
  `omarchy-launch-or-focus`. Lua: `hl.get_windows()` filter, then
  `hl.dsp.focus({ window = w })` or `exec_cmd(browser)`. inferred API.
- [ ] **K12 Terminal in the focused terminal's cwd** for `SUPER+Return`:
  read `/proc/<pid>/cwd` of the active window's pid, pass to `ghostty
  --working-directory`. Omarchy `omarchy-cmd-terminal-cwd`.
- [ ] **K13 Smart move**: `SUPER+SHIFT+arrows` move floating windows by
  pixels and tiled windows by direction using
  `hl.get_active_window().floating`. Both HyDE (`move_window(dir, pix)`)
  and Momijiichigo's
  [hotkey_parser gist](https://gist.github.com/Momijiichigo/ee457aa10693df151ebf74c42d47ce68)
  implement it. No new chord.
- [ ] **K14 Passthrough submap**: `SUPER+ALT+F1` enters a submap with no
  binds (for VMs, RDP, games); the same chord with `submap_universal =
  true` exits, with a `notify-send` on each transition. From end-4;
  postsolar's `noop` submap is the minimal form.
- [ ] **K15 Hold-to-drag on keys**: `SUPER+Z` = `window.drag()`,
  `SUPER+X` = `window.resize()`, both `{ mouse = true }`. Move/resize while
  holding a key instead of a mouse button. From HyDE.
- [ ] **K16 Game mode chord**: `SUPER+SHIFT+ALT+G` runs S2. `SUPER+SHIFT+G`
  (JaKooLit's chord) is **taken** by group move here.
- [ ] **K17 Dynamic gaps**: `SUPER+ALT+Minus` / `SUPER+ALT+Equal` adjust
  `general.gaps_in` by 3 live (postsolar's outer-gap chord). Useful for
  screenshots and demos.
- [ ] **K18 Exact 640x480**: `SUPER+CTRL+Backslash` =
  `hl.dsp.window.resize({ x = 640, y = 480, "exact" })`. From end-4.
- [ ] **K19 Push-to-talk pattern**: two binds on one key, the second with
  `release = true` (Omarchy F9 dictation). No current consumer; recorded as
  a pattern for future use.

### 4.3 Hygiene and philosophy

- [ ] **K20 Harder exit chord**: move `hyprshutdown` from `SUPER+M` to
  `SUPER+ALT+M`. Several people in the "default keybinds" thread do this
  after one accidental logout.
- [ ] **K21 `caps:swapescape`** in `input.kb_options`. Tap-Caps-for-Esc /
  hold-Caps-for-Super is **not** achievable in Hyprland alone (confirmed in
  the thread); it needs `keyd`.
- [ ] **K22 Bind descriptions**: add `{ description = "..." }` to every
  `hl.bind` so any `hyprctl -j binds` consumer (including a future
  keybind cheatsheet) can render them. HyDE and end-4 do this throughout.
- [ ] **K23 Alt+F4 coaching**: `ALT+F4` bound `non_consuming` to
  `notify-send "Super+Shift+Q closes windows"`. end-4's trick for
  retraining muscle memory; delete once unneeded.

Philosophy that recurred across every source: keep the desktop on SUPER
and leave CTRL/ALT to applications, tmux and the editor.

### 4.4 Already present here (do not re-add)

Clipboard history (`SUPER+CTRL+V`), symbol picker (`SUPER+CTRL+Space`),
prose-symbol picker (`SUPER+CTRL+P`), keybindings menu (right-click on the
command-centre module), scratchpad `magic` (`SUPER+S`, `SUPER+SHIFT+S`),
full group set (`SUPER+G`, `Tab`, `SHIFT+Tab`, `SHIFT+G`, `CTRL+G`,
`CTRL+SHIFT+G`), scrolling-layout column operations, i3-style
`SUPER+slash` fullscreen, pk-wiki on `SUPER+grave` (runtime).

## 5. Reserved chords (current state)

| Chord | Action |
| --- | --- |
| `SUPER+Return` | terminal |
| `SUPER+Space`, `SUPER+R` | rofi drun |
| `SUPER+B` | browser |
| `SUPER+L` | hyprlock |
| `SUPER+SHIFT+C`, `SUPER+SHIFT+Q` | close window |
| `SUPER+M` | hyprshutdown / exit |
| `SUPER+E` | ranger |
| `SUPER+CTRL+V` | clipboard menu |
| `SUPER+CTRL+Space` | symbol picker |
| `SUPER+CTRL+P` | prose symbol picker |
| `SUPER+V` | toggle float |
| `SUPER+F`, `SUPER+slash` | fullscreen |
| `SUPER+P` | pseudo |
| `SUPER+J` | togglesplit |
| `SUPER+G`, `SUPER+Tab`, `SUPER+SHIFT+Tab`, `SUPER+SHIFT+G`, `SUPER+CTRL+G`, `SUPER+CTRL+SHIFT+G` | groups |
| `SUPER+arrows` | focus |
| `SUPER+SHIFT+arrows` | move window |
| `SUPER+CTRL+arrows` | resize |
| `SUPER+comma`, `SUPER+period` | scrolling `move -col/+col` |
| `SUPER+CTRL+comma`, `SUPER+CTRL+period` | scrolling `focus l/r` |
| `SUPER+SHIFT+comma`, `SUPER+SHIFT+period` | scrolling `swapcol l/r` |
| `SUPER+CTRL+I`, `SUPER+CTRL+O` | scrolling consume/expel |
| `SUPER+0..9`, `SUPER+SHIFT+0..9` | workspace focus / move |
| `SUPER+S`, `SUPER+SHIFT+S` | special workspace `magic` |
| `SUPER+mouse_down/up` | workspace e+1 / e-1 |
| `SUPER+mouse:272`, `SUPER+mouse:273` | drag / resize |
| `SUPER+grave`, `SUPER+SHIFT+grave` | pk-wiki toggle / hide (runtime, `bin/pk-wiki`) |
| `XF86Audio*`, `XF86MonBrightness*` | media and brightness |

## 6. Verification plan for accepted items

1. **Waybar modules**: before any module reaches `config.jsonc`, instantiate
   it for one second and grep for `Unknown module` / `Disabling`:

   ```sh
   timeout 3 waybar -c <tmp.jsonc> -s /dev/null -l info 2>&1 \
     | grep -iE 'Unknown module|Disabling|Bar configured'
   ```

   This is the check that disproved the `strings`-based cava claim; treat
   nothing as available until it passes.
2. **Layer rule**: `hyprctl layers` to confirm the namespace is exactly
   `waybar`; screenshot the bar over a busy window with and without the rule.
3. **Keybinds**: `hyprctl -j binds | jq '.[] | select(.key=="...")'` after
   reload for each new chord; live-test repeating/release flags.
4. **Nix**: `nix eval '.#homeConfigurations.cbox.activationPackage'
   --no-build`, then `home-manager switch --flake .#cbox --dry-run` before
   the real switch. Font additions (B2) go through the host profile.
5. **Reload path**: Hyprland `config.reloaded` re-asserts the desktop
   services; Waybar picks up `reload_style_on_change`. Neither needs a
   session restart.

## 7. Sources

- Waybar themes: [sejjy/mechabar](https://github.com/sejjy/mechabar),
  [HANCORE-linux/waybar-themes](https://github.com/HANCORE-linux/waybar-themes),
  [atif-1402/minimal-waybar-themes](https://github.com/atif-1402/minimal-waybar-themes)
  (config read: `waybar/V3.Ωx/config.jsonc`),
  [rose-pine/waybar](https://github.com/rose-pine/waybar),
  [catppuccin/waybar](https://github.com/catppuccin/waybar),
  [mechatour/amber_gold.dotfiles](https://github.com/mechatour/amber_gold.dotfiles).
- Keybinds: Omarchy
  [bindings.conf](https://raw.githubusercontent.com/basecamp/omarchy/master/config/hypr/bindings.conf),
  [tiling-v2.conf](https://raw.githubusercontent.com/basecamp/omarchy/master/default/hypr/bindings/tiling-v2.conf),
  [utilities.conf](https://raw.githubusercontent.com/basecamp/omarchy/master/default/hypr/bindings/utilities.conf),
  [media.conf](https://raw.githubusercontent.com/basecamp/omarchy/master/default/hypr/bindings/media.conf);
  end-4 [keybinds.lua](https://raw.githubusercontent.com/end-4/dots-hyprland/main/dots/.config/hypr/hyprland/keybinds.lua);
  HyDE [key_binds.lua](https://raw.githubusercontent.com/HyDE-Project/HyDE/master/Configs/.local/share/hypr/lua/key_binds.lua)
  and [layer_rules.lua](https://raw.githubusercontent.com/HyDE-Project/HyDE/master/Configs/.local/share/hypr/lua/layer_rules.lua);
  [JaKooLit Keybinds wiki](https://github.com/JaKooLit/Hyprland-Dots/wiki/Keybinds);
  [postsolar keybindings.conf](https://github.com/postsolar/config/blob/4c745650cf99297b978397246641eda22918dd89/home-manager/hyprland/keybindings.conf);
  [Momijiichigo hotkey_parser gist](https://gist.github.com/Momijiichigo/ee457aa10693df151ebf74c42d47ce68).
- Community threads (read via a Redlib mirror):
  [Keybinding favorites](https://www.reddit.com/r/hyprland/comments/1cqs5g0/keybinding_favorites/),
  [Share your Hyprland custom keybinds](https://www.reddit.com/r/archlinuxwithlove/comments/1s1zveo/share_your_hyprland_custom_keybinds/),
  [Are you using default keybinds?](https://www.reddit.com/r/hyprland/comments/1kuhnwj/are_you_using_default_keybinds/),
  [Liquid glass effect on Waybar](https://www.reddit.com/r/hyprland/comments/1mwkbtd/liquid_glass_effect_on_waybar/).
- Hyprland wiki: [Layer rules](https://wiki.hypr.land/configuring/core/rules/layer-rules/).
- Local evidence: `pacman -Qi waybar`, `ldd /usr/bin/waybar`, two
  one-second `waybar -c` harness runs, `lspci -nn`, `nvidia-smi`,
  `/sys/class/hwmon/*/name` with `readlink -f .../device`, `id -nG`,
  `configs/hypr/hyprland.lua`, `configs/waybar/*`,
  `nix/modules/hyprland-desktop.nix`, `bin/pk-wiki`.
