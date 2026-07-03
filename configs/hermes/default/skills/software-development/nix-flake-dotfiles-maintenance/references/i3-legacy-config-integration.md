# Integrating legacy i3 config into Nix/Home Manager dotfiles

Use this when porting old i3/i3-gaps configs from this dotfiles repo into a host-scoped Home Manager profile.

## Discovery pattern

1. Treat the local dotfiles repo as the primary source before remote hosts if the user says legacy config is in `dotfiles`.
2. Search both current tree and Git history:
   - current paths: `.old/i3config`, `configs/i3/config`, `configs/rofi`, `configs/polybar`
   - history paths: `git log --all --name-status -- '*i3*' '*rofi*' '*polybar*' '*OLD*' '*old*' '*legacy*'`
   - content: `git grep -I -n -i -E 'i3bar|i3status|bumblebee-status|polybar|rofi' $(git rev-list --all) --`
3. Be careful with broad text searches: `rofi` appears inside words like `profile`; use a boundary-aware pattern such as `\brofi\b` or inspect path matches first.
4. If a subagent reports "not found" but the user corrects scope, immediately re-run local discovery yourself with narrower patterns instead of defending the prior result.

## Known local legacy source

The old i3 config is currently available as:

- `.old/i3config`

It was historically imported from the fancy legacy directory:

- `░▒▓ OLD ▓▒░/i3config`
- commit `839f09ed3c5a4f388fd443bfefa63f3ca22510cf` (`Move remaining old configs`)

The file contains an old `i3bar` block with `i3status` plus commented `bumblebee-status`/powerline examples. It does not contain real Rofi or Polybar configs.

## Porting guidance

- Do not blindly install every legacy dependency. The old config references Manjaro-era tools (`urxvt`, `xfce4-terminal`, `i3-dmenu-desktop`, `morc_menu`, `compton`, `pamac-tray`, etc.) that should be replaced or omitted.
- Preserve durable UX choices, but re-check whether the user still wants the historical keyboard ergonomics:
  - `Mod4`
  - workspace labels/icons
  - gaps/resize modes
  - color palette (`#2B2C2B`, `#16A085`, etc.)
  - `░▒▓` visual motif when creating new bar/launcher themes
  - legacy Dvorak/Programmer-Dvorak bindings only if the user still uses that layout; otherwise switch workspace bindings back to the standard number row.
- Prefer modern packages and names on nixpkgs 26.05:
  - use `pkgs.i3`; `pkgs.i3-gaps` is renamed/replaced by `pkgs.i3`
  - use `pkgs.picom`; not legacy `compton`
  - use top-level `pkgs.xkill` and `pkgs.setxkbmap`; not `pkgs.xorg.xkill` / `pkgs.xorg.setxkbmap`
- Do not make the i3 module own Ghostty configuration just because i3 launches Ghostty. On cbox Ghostty may already be installed and have an unmanaged `~/.config/ghostty/config`; importing `nix/modules/ghostty.nix` from `i3-desktop.nix` can make Home Manager fail with a clobber warning. Prefer `set $terminal ghostty` and update Rofi's `terminal: "ghostty";` while leaving Ghostty config ownership alone unless the user explicitly asks to manage it declaratively.
- Keep Polybar and i3status-rust mutually exclusive by default:
  - Polybar = replacement bar
  - i3status-rust = fallback for `i3bar`/i3bar-protocol
- For macOS-to-i3 transition comfort, consider discoverability and launcher ergonomics before deep keyboard emulation:
  - bind `Super+Space` to Rofi while preserving `Super+Shift+Space` for floating toggle.
  - consider `rofi -show combi` for Spotlight/Raycast-like apps + commands + windows.
  - consider a Rofi keybinding cheat sheet, window switcher, screenshots, clipboard history, and a dedicated scratch terminal.
  - invert Polybar workspace wheel direction with `reverse-scroll = true` in `[module/i3]` when the user asks for inverted bar scrolling.

## Home Manager wiring pattern

Create a host-scoped module such as `nix/modules/i3-desktop.nix` and import it from a host/profile. Keep config sources under XDG-shaped `configs/` paths:

```nix
{ dotfiles, pkgs, ... }:
{
  home.packages = with pkgs; [
    i3
    i3lock
    alacritty
    rofi
    dunst
    libnotify
    pavucontrol
    networkmanagerapplet
    picom
    xkill
    setxkbmap
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  xdg.configFile."i3/config".source = dotfiles + "/configs/i3/config";
  xdg.configFile."rofi/config.rasi".source = dotfiles + "/configs/rofi/config.rasi";
  xdg.configFile."rofi/themes/sourcerer.rasi".source = dotfiles + "/configs/rofi/themes/sourcerer.rasi";

  services.polybar = {
    enable = true;
    package = pkgs.polybar;
    config = dotfiles + "/configs/polybar/config.ini";
    script = "polybar main &";
  };
}
```

## Verification

- Stage newly added imported files before flake evaluation.
- Evaluate the target Home Manager config:

```bash
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
```

- Validate i3 syntax without starting a session:

```bash
nix shell --inputs-from . nixpkgs#i3 -c i3 -C -c /home/swe/dotfiles/configs/i3/config
```

- Run `git diff --cached --check` before finalizing.
