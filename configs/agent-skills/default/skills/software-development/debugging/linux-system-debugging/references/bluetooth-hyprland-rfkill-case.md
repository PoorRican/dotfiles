# Authentication and desktop devices

## PAM and screen lockers

`pam_faillock` tracks failures per user across PAM services that include it. A first TTY failure can complete a tally that already includes screen-locker or sudo attempts. Inspect `faillock --user <user>`, relevant PAM service stacks and journal entries before resetting a tally or changing policy. Failed privilege-escalation attempts can add to the tally, so avoid blind retries.

If a locker was already running when PAM configuration changed, compare its start time with the configuration modification time; an existing PAM conversation may reflect the earlier stack. Check keyboard firmware layers and stuck modifiers as well as the OS layout when graphical login fails.

A replacement locker may still use the same PAM stack. Stop or update stale idle triggers that can relaunch the old locker; keep manual and idle entrypoints consistent. Starting a real lock or terminating a locker affects access to the session: obtain authorization and ensure a recovery path first.

Inspect `/etc/security/faillock.conf` and the affected files in `/etc/pam.d/`; correlate `faillock --user "$USER"` with `journalctl -b -g 'pam_faillock|pam_unix|FAILED LOGIN'`. If policy is too strict, `deny`, `fail_interval`, and `unlock_time` control the tradeoff. A service-specific PAM change can exclude a locker from lockout accounting without weakening other services.

## Bluetooth and session integration

- Inspect controller enumeration, kernel and Bluetooth service logs, `bluetoothctl show`, and `rfkill list bluetooth` before blaming a GUI or antenna. `off-blocked` or `NotReady` calls for checking power and rfkill. Successful scanning with plausible RSSI supports a working radio path, not necessarily a working peripheral.
- A bonded device need not be awake or advertising. Check fresh discovery or RSSI and wake the peripheral before removing a bond. A reset or privacy address can make an old saved address stale.
- Custom desktop sessions may lack a Bluetooth applet or a user-session Polkit authentication agent even when the system daemon is running. A graphical user service can also fail if its session target or display environment is absent; inspect the user unit and imported session environment.
- Before changing rfkill state, identify the correct device and distinguish soft from hardware blocking; check persisted systemd-rfkill state when a block returns after restart.

For a live Wayland session whose user unit fails because its graphical target or display environment is missing, import the session environment before starting a transient user unit:

```bash
systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS PATH
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS PATH
systemd-run --user --unit=waybar-manual --collect \
  --property=Environment=DISPLAY="$DISPLAY" \
  --property=Environment=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  --property=Environment=XDG_CURRENT_DESKTOP="$XDG_CURRENT_DESKTOP" \
  --property=Environment=XDG_SESSION_TYPE="$XDG_SESSION_TYPE" \
  --property=Environment=HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_INSTANCE_SIGNATURE" \
  waybar
```

The same transient-unit pattern can start `blueman-applet` or a Polkit agent. Check the unit status and the original symptom afterward. For BLE HID, verify `bluetoothctl info <addr>` and the input device in `/proc/bus/input/devices` after connection.
