---
name: cbox-desktop-live-preview
description: "Use when changing the cbox Hyprland, Waybar, rofi, dunst, hyprlock, hypridle or Ghostty look, binds or lock/idle wiring and the user wants live previews without killing windows, then an approved, isolated commit and Home Manager deploy."
---

# cbox desktop live preview

Goal: show desktop changes live (reload-only: never restart Hyprland or close windows), collect feedback, then commit only the owned files and deploy through Home Manager. Home Manager deploys the repository's configs to `~/.config` as read-only Nix store links, so editing the repository changes nothing in the live session until activation; a preview therefore has to load the edited files by hand and put everything back afterwards.

## Rules that hold for every surface

- Reload-only. Do not restart Hyprland, close windows or run `hyprctl reload` during a preview: the `config.reloaded` hook re-asserts every desktop user service (including `hypr-waybar.service`), so a reload with a preview bar alive leaves two bars.
- The repository is not the whole truth. The desktop palette is generated from `my.desktop.theme` (`nix/modules/desktop-theme.nix`) into `~/.config/waybar/theme.css`, `~/.config/hypr/desktop-theme.lua`, a hyprlock theme, rofi `themes/desktop.rasi` and Ghostty `themes/desktop`; none of those exist in the repository checkout. A preview that points a program at repo files alone renders without the palette. Use a Home Manager-built generation or copy the deployed generated file next to the scratch copy you preview.
- Never trigger hyprlock yourself (it locks the live session); hand the user the command instead.
- Check underlying state before calling a module oddity a theme bug (for example `wpctl get-volume` when the volume module shows `vol --`).
- Commit only owned paths; a shared checkout often holds someone else's uncommitted work.

| When you are… | Open |
|---|---|
| Previewing a Hyprland option block, Waybar, rofi, dunst or Ghostty change in the live session, or capturing screenshots for feedback | [references/surface-previews.md](references/surface-previews.md) |
| Building a Home Manager generation free of foreign WIP, committing after approval, or ending a preview with a switch | [references/build-commit-and-deploy.md](references/build-commit-and-deploy.md) |
| Changing or debugging the lock screen, idle lock, display power-off or the lock PAM file | [references/hyprlock-and-hypridle-deployment.md](references/hyprlock-and-hypridle-deployment.md) |
