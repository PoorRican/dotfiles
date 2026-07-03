# i3/X11 lockscreen replacement during `pam_faillock` incidents

## Situation

A user on X11+i3 had repeated `i3lock` authentication failures recorded as `pam_faillock` entries from source `:0`. The failures were not caused by OS keyboard layout: XKB reported `us`/QWERTY and the user confirmed the Dvorak Kinesis keyboard is expected to emit regular US keycodes. Killing stale `i3lock` immediately restored access to the X session.

## Durable lessons

- When the user just wants to regain the X session, killing `i3lock` is appropriate after preserving evidence:

  ```bash
  pgrep -a -u "$USER" 'i3lock|xss-lock'
  kill $(pgrep -u "$USER" i3lock)
  faillock --user "$USER"
  ```

- Stop stale idle triggers before testing a replacement, otherwise `xss-lock -- ... i3lock` can relaunch the old locker:

  ```bash
  pkill -u "$USER" -x xss-lock 2>/dev/null || true
  ```

- Prefer a single wrapper entrypoint, e.g. `~/.local/bin/i3-lock`, so manual i3 bindings and idle/suspend hooks can be switched together.
- `betterlockscreen` is primarily an aesthetic wrapper around `i3lock-color`; it improves appearance but does **not** by itself remove the PAM/faillock class of behavior.
- In i3 config, prefer:

  ```i3
  set $locker i3-lock
  exec --no-startup-id xss-lock --transfer-sleep-lock -- $locker
  bindsym ... exec --no-startup-id $locker
  ```

- Cache/update `betterlockscreen` images without locking first:

  ```bash
  betterlockscreen --quiet --update /path/to/image.png
  ```

- Verify cache and lock state before telling the user to test:

  ```bash
  find ~/.cache/betterlockscreen -maxdepth 2 -type f | sort
  faillock --user "$USER"
  pgrep -a -u "$USER" 'xss-lock|betterlockscreen|i3lock'
  ```

## Safe testing guidance

Do not trigger an actual lock from the agent unless the user explicitly asks and has an escape path. Give the user an emergency recovery command from TTY/SSH:

```bash
pkill -u swe i3lock
```

If the lockscreen is still in the `i3lock` family (`i3lock`, `i3lock-color`, `betterlockscreen`), failed unlock attempts may still increment the same `pam_faillock` tally unless the PAM service is separated or tuned.
