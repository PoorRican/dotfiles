---
name: cbox-desktop-live-preview
description: Preview cbox Hyprland desktop, Waybar, rofi, dunst, Ghostty and lock/idle changes without restarting the session, then deploy approved changes through Home Manager.
---

# cbox desktop live preview

Home Manager links live configuration to generated, read-only files. Repository edits therefore need an explicit preview, including the generated palette, before activation.

- Do not restart Hyprland, close windows, or trigger hyprlock during a preview. Ask the user to test the lock.
- Avoid `hyprctl reload` while a preview bar is running: the reload hook reasserts desktop services and can create a second bar.
- Commit and deploy only with approval; keep unrelated changes out of the build and commit.

| Task | Reference |
|---|---|
| Preview desktop surfaces, capture feedback, and build or deploy an approved preview | [Surface previews and deployment](references/surface-previews.md) |
| Change or troubleshoot cbox lock and idle wiring | [Lock and idle](references/hyprlock-and-hypridle-deployment.md) |
