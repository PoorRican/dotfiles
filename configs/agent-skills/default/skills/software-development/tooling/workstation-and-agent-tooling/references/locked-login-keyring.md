# Locked GNOME login keyring

Scope: Diagnosing `gh` or git-over-https calls that hang because the GNOME login keyring is locked with no unlock prompt, and the owner-run unlock over the Secret Service D-Bus API. This documents how, not whether: the owner decides to unlock, types the password, and decides any permanent change.

## Symptoms
- Every `gh` call hangs (`gh api user`, `gh auth status`); `git push` over https hangs when the credential helper is `!gh auth git-credential`.
- `~/.config/gh/hosts.yml` has no `oauth_token` line, meaning the token is kept in the keyring. Check with `grep -c oauth_token` (a count, not the value).
- No unlock prompt appears, so asking the owner to "run `gh auth status`" does not help.

## Diagnose without reading secrets
Never read secret values and never run `secret-tool search`, which prints them. These commands are read-only:
```bash
busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked   # b true = locked
loginctl list-sessions; loginctl show-session <n> -p Service -p Type   # Service=lightdm-autologin = root cause
journalctl --user --since -90min | grep -E 'gcr-prompter|gnome-keyring'   # did any prompt actually show?
ls -la /run/user/$(id -u)/bus   # bus socket time = when the session restarted
```
- On an autologin seat PAM receives no password, so `pam_gnome_keyring` cannot unlock the `login` collection, which stays locked after every boot. The `Service=` value depends on how the session started.

## Unlock (owner runs it in their own terminal)
- The agent never sees, pipes or stores the password. Save the script as `unlock_login_keyring.py` in a workspace directory (not `/tmp`) and have the owner run `uv run --no-project --with jeepney python unlock_login_keyring.py`. The script parses and its imports resolve under jeepney 0.9.0 (checked 2026-11-10); it was not run against a live keyring in this check.

```python
import getpass
import sys

from jeepney import DBusAddress, new_method_call
from jeepney.wrappers import DBusErrorResponse, unwrap_msg
from jeepney.io.blocking import open_dbus_connection

COLLECTION = "/org/freedesktop/secrets/collection/login"
SERVICE = DBusAddress("/org/freedesktop/secrets", bus_name="org.freedesktop.secrets",
                      interface="org.freedesktop.Secret.Service")
INTERNAL = DBusAddress("/org/freedesktop/secrets", bus_name="org.freedesktop.secrets",
                       interface="org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface")
PROPS = DBusAddress(COLLECTION, bus_name="org.freedesktop.secrets",
                    interface="org.freedesktop.DBus.Properties")


def call(conn, msg):
    return unwrap_msg(conn.send_and_get_reply(msg))  # error replies raise DBusErrorResponse


def locked(conn) -> bool:
    (_, value), = call(conn, new_method_call(PROPS, "Get", "ss",
                                             ("org.freedesktop.Secret.Collection", "Locked")))
    return bool(value)


def main() -> int:
    with open_dbus_connection(bus="SESSION") as conn:
        if not locked(conn):
            print("login keyring is already unlocked")
            return 0
        password = getpass.getpass("Login keyring password: ")
        _, session = call(conn, new_method_call(SERVICE, "OpenSession", "sv", ("plain", ("s", ""))))
        try:
            call(conn, new_method_call(
                INTERNAL, "UnlockWithMasterPassword", "o(oayays)",
                (COLLECTION, (session, b"", password.encode(), "text/plain"))))
        except DBusErrorResponse as err:
            print(f"not unlocked: {err.name}: {err.data[0] if err.data else ''}")
            return 1
        finally:
            del password
        if locked(conn):
            print("daemon accepted the call but the keyring is still locked")
            return 1
        print("login keyring unlocked")
        return 0


if __name__ == "__main__":
    sys.exit(main())
```

- The agent may test the wiring only with a deliberately wrong password the owner has agreed to; the expected result is `not unlocked: org.gnome.keyring.Error.Denied: The password was invalid` with no side effects [INFERENCE: not re-run here]. Then verify `Locked` reads `b false` and `gh auth status` lists the scopes.

## Pitfalls
- In jeepney 0.9, `unwrap_msg` and `DBusErrorResponse` live in `jeepney.wrappers`, not the top-level package. `DBusConnection.send_and_get_reply` returns D-Bus error replies as ordinary messages and does not raise (checked in the 0.9.0 source, 2026-11-10); without `unwrap_msg` a wrong password looks like success.
- The plain session must be opened on the same connection as the unlock call: sessions are per-connection, so one-shot `busctl` or `gdbus` calls cannot do it.
- If the owner's current login password is rejected, the keyring was created with a different (often older) password.
- The permanent fix belongs to the owner: disable display-manager autologin so PAM unlocks the keyring at login, or re-run the script after each reboot. Do not edit the display-manager configuration (for LightDM, `/etc/lightdm`) or reset the keyring file (`~/.local/share/keyrings/login.keyring`; that loses stored secrets) without an explicit owner decision.

Related skills: debugging (PAM and Linux host diagnosis).
