# cbox BLE HID Bluetooth workflow

Session-derived workflow for debugging Kinesis Adv360 Pro / BLE HID connectivity on cbox. Applies to both the older i3/Polybar setup and the newer Hyprland/Waybar setup.

## Symptoms this workflow covers

- Blueman applet/manager rapidly oscillates connect/disconnect for a BLE keyboard.
- Window manager shows many small Blueman GTK windows titled with the device name (for example `Adv360 Pro`).
- BlueZ state becomes internally stale: `Trusted: yes` while `Paired: no` and `Bonded: no`.
- Direct `bluetoothctl connect <MAC>` briefly sets `Connected: yes`, then fails with `org.bluez.Error.Failed le-connection-abort-by-local`.
- RSSI is extremely weak (`-104` to `-107 dBm`) for a desk keyboard.
- On Hyprland/Waybar, clicking the Bluetooth widget opens a manager UI but connection attempts still fail or no applet/agent is actually running.

## Key lessons

1. **Separate adapter health from device/RF health.** If `bluetoothctl scan on` discovers several nearby devices with normal RSSI (for example around `-50 dBm`), the controller, driver, and antenna path are probably functional. A single device with `-90 dBm` or worse is more likely a device-specific RF/battery/distance/pairing-mode/interference issue than a globally dead Bluetooth adapter.

2. **Do not treat Blueman as authoritative for BLE HID.** Blueman can add noise through popup storms or a half-running applet. Use direct BlueZ commands first, then reintroduce Blueman after the state is clean.

3. **A one-shot `bluetoothctl --timeout ...` is not a real pairing agent session.** If the command exits, the `KeyboardDisplay` agent exits too, and `Pairable` may revert. For pairing that needs a passkey, keep an interactive `bluetoothctl --agent KeyboardDisplay` session open while the device is in pairing mode.

4. **Hyprland/Waybar adds a UI/session layer.** Check whether `blueman-applet.service` is actually active and whether a polkit/authentication agent exists. The manager window alone is not proof that the applet/agent path is healthy.

5. **Kinesis Adv360 Pro can appear as USB while Bluetooth is broken.** Kernel logs showing `Kinesis Corporation Adv360 Pro` under USB/HID mean the keyboard is usable over USB; they do not prove the BLE pairing path is healthy.

## Diagnostic commands

Adapter and service health:

```bash
systemctl --no-pager --full status bluetooth.service
rfkill list bluetooth
bluetoothctl list
bluetoothctl show
btmgmt info
hciconfig -a
journalctl -u bluetooth.service -b --no-pager | tail -250
journalctl -k -b --no-pager | grep -Ei 'bluetooth|btusb|hci0|firmware|usb' | tail -250
```

Adapter identity / driver research:

```bash
readlink -f /sys/class/bluetooth/hci0/device
udevadm info -q property -p "$(readlink -f /sys/class/bluetooth/hci0/device)" | sort
btmgmt info
lsmod | grep -Ei 'btusb|bluetooth|btintel|btbcm|btrtl|btmtk|hidp|uhid|hid_'
```

Discovery/RSSI sanity check:

```bash
bluetoothctl --timeout 25 scan on
bluetoothctl devices
for mac in $(bluetoothctl devices | awk '{print $2}'); do
  echo "--- $mac"
  bluetoothctl info "$mac" | sed -n '1,120p'
done
```

Interpretation:

- Many devices found with RSSI much better than `-90 dBm` => adapter/driver/radio path likely works.
- Target HID device only seen at `-90 dBm` or worse, or not seen while nearby/in pairing mode => check keyboard side, battery, distance, antenna, RF/USB interference, metal case placement, and whether the device is actually advertising in the correct pairing slot.

Device state and stale bonds:

```bash
bluetoothctl devices
bluetoothctl info <MAC>
busctl --system tree org.bluez --list | grep -E '/org/bluez/(hci|.*dev_)'
```

Hyprland/Waybar/Blueman session layer:

```bash
systemctl --user --no-pager --full status blueman-applet.service
pgrep -af 'blueman|bluez|bluetoothd|polkit|policy'
journalctl --user --since '45 min ago' --no-pager | grep -Ei 'blueman|bluez|bluetooth|obex|polkit|policy'
gsettings list-recursively org.blueman.plugins.recentconns 2>/dev/null || true
```

For i3 popup storms only:

```bash
i3-msg -t get_tree | jq -r '.. | objects | select(.window_properties?.class? != null) | select((.window_properties.class|test("(?i)blueman|blue")) or (.name|test("(?i)blueman|blue|Adv360"))) | [.id,.name,.focused,.window_properties.class] | @tsv'
```

## Stabilization pattern

1. Stop the noisy UI layer before debugging BlueZ state:

```bash
pkill -f 'blueman-applet|blueman-tray|blueman-manager' || true
# i3 only, if popup windows are present:
i3-msg '[class=".blueman-applet-wrapped"] kill' || true
i3-msg '[class="Blueman-manager"] kill' || true
```

2. Inspect and remove stale unbonded/trusted entries before re-pairing:

```bash
bluetoothctl info <MAC>
bluetoothctl remove <MAC>
```

3. Pair through a live direct BlueZ session, not a short one-shot command:

```bash
bluetoothctl --agent KeyboardDisplay
```

Inside that session:

```text
power on
pairable on
default-agent
scan on
pair <MAC>
trust <MAC>
connect <MAC>
```

If a passkey appears, type it on the keyboard being paired and press Enter on that keyboard.

4. If the device still fails but the adapter scan looked healthy, test device-side variables before driver changes:

- Put the HID device in a fresh Bluetooth pairing slot/mode.
- Move it close to the back-panel antenna area.
- Check/charge battery.
- Temporarily disconnect nearby USB 3 hubs/dongles that may create 2.4 GHz noise.
- Compare against a different Bluetooth peripheral if available.

5. Only after adapter-wide failures (no discovery, controller errors, firmware load errors, rfkill, etc.) should you escalate to driver/kernel/firmware or motherboard BIOS work.

## UI/config lesson

For i3/Polybar setups, avoid autostarting `blueman-applet` when BLE HID reconnect loops are suspected. Keep Blueman installed as a manual fallback, but route the Polybar Bluetooth module to a quiet helper that uses `bluetoothctl` for connect/pair/status and only opens Blueman on an explicit fallback click.

For Hyprland/Waybar setups, remember that Waybar's Bluetooth module and `blueman-manager` are only UI surfaces. A robust setup should also ensure any needed applet/authentication agent is actually started in the active Wayland session, and troubleshooting should still begin with direct `bluetoothctl`/BlueZ state.
