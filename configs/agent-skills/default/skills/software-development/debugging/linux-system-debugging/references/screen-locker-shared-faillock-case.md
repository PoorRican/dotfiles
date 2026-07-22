# Case note: screen-locker failures causing apparent early TTY lockout

## Symptom

User reported sometimes being unable to use the `swe` password before the expected 3-password lockout threshold.

## Evidence pattern

`faillock --user swe` showed three valid failures:

```text
2026-06-09 15:58:15 TTY :0        V
2026-06-09 15:58:42 TTY :0        V
2026-06-09 15:59:35 TTY /dev/tty2 V
```

Journal around the third entry showed:

```text
unix_chkpwd: password check failed for user (swe)
login: pam_unix(login:auth): authentication failure ... tty=/dev/tty2 user=swe
login: pam_faillock(login:auth): Consecutive login failures for user swe account temporarily locked
FAILED LOGIN 1 FROM tty2 FOR swe, Authentication failure
```

PAM files showed the screen locker shared the normal auth stack:

```text
/etc/pam.d/i3lock:
auth include system-auth

/etc/pam.d/system-auth:
auth required pam_faillock.so preauth
auth [success=1 default=bad] pam_unix.so try_first_pass nullok
auth [default=die] pam_faillock.so authfail
auth required pam_faillock.so authsucc
```

## Interpretation

The TTY login was not the first failure in the active faillock window. Two earlier graphical-session (`:0`) failures had already been counted, likely via `i3lock`, so one TTY failure became the third shared failure and triggered lockout.

## Additional clue

Kernel/journal lines around the same time showed a Kinesis Adv360 keyboard reconnect shortly before the `i3lock` failures and disconnect shortly after. The user later clarified this reconnect was manual/expected, so do not over-weight reconnects by themselves. The more durable keyboard hypothesis is firmware/input-layer mismatch: OS XKB may remain `us` QWERTY while a programmable keyboard layer/layout sends Dvorak/Colemak-equivalent characters.

## Sudo escalation pitfall

During mitigation, non-interactive `sudo -v`/`pkexec` attempts failed because no controlling terminal/auth agent was available. Those attempts still created valid `faillock` records for service `sudo`, leaving the account closer to lockout. In auth-lockout debugging, failed privilege escalation is not harmless: after any sudo failure, inspect `faillock --user <user>` and avoid retrying until the credential path is known to work.

## Lesson

When users say they were locked out before the configured number of attempts, inspect the shared per-user faillock tally before focusing on the visible prompt.