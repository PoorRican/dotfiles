# i3 Toolbox widget and long-running helper verification

Context: cbox/i3 uses Home Manager-managed i3/Polybar config and JetBrains Toolbox. Toolbox exposes a small widget/window plus a background process/daemon.

## Toolbox widget behavior

- `i3-msg '[class="jetbrains-toolbox"] kill'` sends WM_DELETE to the Toolbox widget window. In observed Toolbox behavior this dismisses only the widget; the long-running `/usr/bin/jetbrains-toolbox` and `jetbrainsd` processes stay alive.
- A secondary `/usr/bin/jetbrains-toolbox` invocation can ask the already-running Toolbox instance to show the widget again. This makes a dedicated i3 binding more reliable than depending on the tray icon when the StatusNotifier/AppIndicator bridge is flaky.
- Practical helper pattern:

```bash
criteria='[class="jetbrains-toolbox"]'
if i3-msg "$criteria focus" >/dev/null 2>&1; then
  exit 0
fi
/usr/bin/jetbrains-toolbox >/dev/null 2>&1 &
for _ in $(seq 1 40); do
  sleep 0.1
  if i3-msg "$criteria focus" >/dev/null 2>&1; then
    exit 0
  fi
done
notify-send -t 3000 "Toolbox" "JetBrains Toolbox did not appear in time"
```

## Dismiss-on-focus-loss helper

Use an i3 window subscription and close only the Toolbox widget when focus moves away:

```bash
i3-msg -t subscribe -m '["window"]' \
  | jq -r --unbuffered 'select(.change == "focus") | (.container.window_properties.class // "")' \
  | while IFS= read -r focused_class; do
      if [ "$focused_class" != "jetbrains-toolbox" ]; then
        i3-msg '[class="jetbrains-toolbox"] kill' >/dev/null 2>&1 || true
      fi
    done
```

## i3 autostart pitfall for long-running helpers

For one-shot commands, a direct i3 `exec` line is usually enough. For long-running helper scripts with pipes/subscriptions, verify runtime state after `i3-msg reload`; do not assume the autostart line means the helper is alive.

Verification commands:

```bash
i3-msg -t get_config | grep -n 'i3-toolbox-autohide'
ps -eo pid,ppid,stat,comm,args | grep -E 'i3-toolbox-autohide|i3-msg -t subscribe|jq -r --unbuffered' | grep -v grep
```

If a direct `exec_always --no-startup-id $local_bin/helper` line does not leave a running process, use an absolute shell wrapper:

```i3
exec_always --no-startup-id /bin/sh -lc 'exec /home/swe/.local/bin/i3-toolbox-autohide'
```

Then reload and verify both the parent script and its `i3-msg -t subscribe`/`jq` pipeline are alive.

## Home Manager Polybar config note

Home Manager may install `~/.config/polybar/config.ini` as a tiny wrapper that only contains an `include-file=/nix/store/...-config.ini`. When verifying a new module, inspect the included store config as well as the top-level symlink:

```bash
readlink -f ~/.config/polybar/config.ini
sed -n '1,160p' ~/.config/polybar/config.ini
# then read the include-file target if present
```

Polybar logs are often the best runtime proof:

```bash
journalctl --user -u polybar.service --since '2 min ago' --no-pager \
  | grep -Ei 'bluetooth|tray|error|warn|module'
```
