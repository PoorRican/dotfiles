# Build, commit and deploy after a preview

Scope: turning an approved preview into a committed, deployed change without sweeping other people's work into it, and ending the preview in the right order.

## Build without foreign WIP

Flake builds only see tracked files, and the checkout often holds someone else's uncommitted work. Build from a detached worktree at `HEAD`:

```sh
W=$(mktemp -d "${SCRATCH_DIR:-$PWD}/dotfiles-head.XXXXXX"); rmdir "$W"
git worktree add --detach "$W" HEAD
# copy only the files you own into $W, then:
git -C "$W" add <owned paths>        # new files must be tracked or the flake cannot see them
gen=$(nix build "$W#homeConfigurations.cbox.activationPackage" --no-link --print-out-paths)
ls "$gen/home-files"                  # inspect the generated files, including the theme outputs
```

Inspect generated files under `$gen/home-files` (dunstrc, Waybar and Hyprland files, generated palettes) rather than trusting the repository text. Remove the worktree when done.

## After approval

1. Commit only the owned paths with explicit `git add <path>` (never `git add .`); use the isolated-line-commit procedure if a file mixes in foreign hunks. One conventional commit per module or topic.
2. Stop the preview units (`cbox-waybar-preview`, `rofi-preview`) and remove scratch copies and any Ghostty preview copies, restoring backups, so activation finds no collisions.
3. Deploy with `home-manager switch --flake .#cbox`. A full cbox activation has been blocked before by unrelated skill-link collisions; report such a blocker instead of forcing the switch.
4. Start `hypr-waybar.service`, then run `hyprctl reload` so the deployed configuration matches what was previewed. The reload re-starts `hypr-waybar.service` and the other desktop user services, which is why the preview unit must already be stopped.
5. Confirm the live symlinks resolve to the new generation (`readlink -f ~/.config/waybar/style.css ~/.config/hypr/hyprland.lua`) and re-check `hyprctl configerrors`.
6. Then move to the next topic the user sequenced; keep one surface per preview round so feedback maps to one commit.

## Notes

- A switch that adds or changes a user service unit needs `systemctl --user daemon-reload` before restarting it, and a service that reads a symlinked config does not pick up a new generation until restarted (see the idle daemon in [hyprlock-and-hypridle-deployment.md](hyprlock-and-hypridle-deployment.md)).
- Compare the built generation's home-files and home-path with the active ones before activation to spot unrelated drift.
