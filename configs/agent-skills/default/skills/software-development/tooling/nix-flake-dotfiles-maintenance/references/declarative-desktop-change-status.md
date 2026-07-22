# Reporting status of declarative desktop changes

When asked "what is the status?" for Home Manager/i3/Polybar changes, distinguish four layers instead of treating a committed dotfiles change as live state:

1. **Repo state** — committed, staged, unstaged, untracked, ahead/behind origin.
2. **Declarative evaluation state** — whether `nix eval '.#homeConfigurations.<host>.activationPackage.drvPath' --no-write-lock-file` passes. If it fails because an imported/referenced file is untracked, the fix is to stage that file, not to conclude the config is bad.
3. **Applied generation state** — whether the current Home Manager generation/config symlinks contain the change. A commit can exist without being active if `home-manager switch` has not run since the commit.
4. **Live runtime state** — whether the expected process/service is actually running and whether the app was restarted after the infrastructure appeared.

Example: for a Polybar tray bridge, a correct status answer should separately say whether `snixembed` is in `home.packages`, whether i3 autostarts it, whether the current `~/.config/i3/config` includes that autostart, whether `snixembed` is on `PATH`/running, and whether JetBrains Toolbox was restarted after the bridge started.

Useful probes:

```bash
git status -sb
git log --oneline -5 --decorate
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
readlink -f ~/.config/i3/config ~/.config/polybar/config.ini
pgrep -af 'snixembed|jetbrains-toolbox|jetbrainsd|polybar'
journalctl --user -u polybar.service --since '15 min ago' --no-pager
```

Pitfall: do not tell the user a desktop change is "done" or "active" just because it is committed. Say "implemented/committed but not applied" when Home Manager has not switched to a generation containing it, or when the live process is absent.
