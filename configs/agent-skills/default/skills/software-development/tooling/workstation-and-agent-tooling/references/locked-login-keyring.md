# Locked GNOME login keyring

`gh` or Git over HTTPS can hang when a credential helper awaits a locked login keyring without showing a prompt. An absent token in the GitHub CLI configuration does not prove a keyring token exists: another authentication source, or no authentication, is possible. Query lock state without reading secrets:

```bash
busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked
```

Autologin can leave the collection locked because PAM receives no login password. Inspect the user keyring journal and session configuration to diagnose the cause. Never use `secret-tool search` for diagnosis: it prints secret values.

If the owner chooses to unlock the keyring, they can run the following script in their own terminal using `uv run --no-project --with jeepney python unlock_login_keyring.py`. They enter the password directly; the agent must not see, pipe, or store it. The plain session and unlock call must share one D-Bus connection. `unwrap_msg` is necessary because error replies otherwise can look like success.

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

Verify the `Locked` property is false afterward. A rejected password can mean a different keyring password, but does not establish the cause. Do not reset the keyring, which loses stored secrets, or change login policy without an explicit owner decision.
