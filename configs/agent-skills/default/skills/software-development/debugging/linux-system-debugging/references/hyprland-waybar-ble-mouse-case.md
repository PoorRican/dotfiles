# Hyprland Waybar + BLE Mouse Connection Case

## Situation

Arch/Hyprland live session. User wanted the Logitech ERGO M575 connected over Bluetooth and suggested starting Waybar again.

Observed state:

- `bluetooth.service` active and controller powered on.
- `rfkill list bluetooth` clear: not soft/hard blocked.
- Saved ERGO M575 record existed and was `Paired: yes`, `Bonded: yes`, `Trusted: yes`, `Connected: no`.
- Keyboard (`Adv360 Pro`) was connected and verified in `/proc/bus/input/devices`, proving BLE HID generally worked.
- `waybar.service` failed with dependency because `graphical-session.target` was inactive and refused manual start.
- `blueman-applet` and `lxqt-policykit-agent` were available but not running.

## Useful commands

Start Waybar in the live session when the packaged user unit is blocked by an inactive graphical target:

```bash
systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS PATH
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS PATH
systemd-run --user --unit=waybar-manual --collect \
  --property=Environment=DISPLAY=$DISPLAY \
  --property=Environment=WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
  --property=Environment=XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP \
  --property=Environment=XDG_SESSION_TYPE=$XDG_SESSION_TYPE \
  --property=Environment=HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE \
  /usr/bin/waybar
```

Start desktop Bluetooth helpers the same way when they are missing from the session:

```bash
systemd-run --user --unit=lxqt-policykit-agent-manual --collect \
  --property=Environment=DISPLAY=$DISPLAY \
  --property=Environment=WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
  --property=Environment=XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP \
  lxqt-policykit-agent

systemd-run --user --unit=blueman-applet-manual --collect \
  --property=Environment=DISPLAY=$DISPLAY \
  --property=Environment=WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
  --property=Environment=XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP \
  blueman-applet
```

Check whether an already bonded BLE HID is actually advertising before thrashing connect/pair commands:

```bash
bluetoothctl info <addr>
bluetoothctl trust <addr>
bluetoothctl connect <addr>
```

Look for a live `RSSI:` field in `bluetoothctl info <addr>` or discovery output. If the saved device has no RSSI/advertising data and `connect` fails with:

```text
Failed to connect: org.bluez.Error.Failed le-connection-abort-by-local
```

then the bond may be valid but the peripheral is not advertising or is asleep. Ask the user to wake the mouse or put it in Bluetooth pairing/discovery mode, then retry. Do not remove the bond unless fresh discovery or logs point to stale pairing.

## Verification

- `pgrep -a waybar` or `systemctl --user status waybar-manual.service` shows Waybar running.
- `bluetoothctl info <mouse-addr>` shows `Connected: yes` after the user wakes/enables advertising.
- `/proc/bus/input/devices` contains the mouse/Logitech HID block after connection.
