# Bluetooth on Hyprland: rfkill + Blueman session integration

This reference condenses a real diagnostic where Bluetooth GUI pairing/connect failed on an Arch/Hyprland desktop with a Qualcomm/Foxconn USB Bluetooth controller.

## Symptoms observed

- Blueman/manager could not reliably connect to devices.
- The initial suspicion was poor connectivity or antenna/driver failure.
- `bluetoothctl scan on` found nearby BLE devices with plausible RSSI when unblocked, which weakened the bad-antenna hypothesis.
- After service/controller reset, BlueZ reported:
  - `PowerState: off-blocked`
  - `SetDiscoveryFilter failed: org.bluez.Error.NotReady`
  - `Failed to start discovery: org.bluez.Error.NotReady`
  - `bluetoothctl power on` failed
- Persisted rfkill state under `/var/lib/systemd/rfkill/...:bluetooth` contained `1`.

## Root causes found

1. **Desktop session integration was incomplete**
   - Hyprland autostart launched Waybar and GUI tools but not `blueman-applet`.
   - `polkitd` was running, but no user-session Polkit auth agent was present.
   - Under custom WMs, this breaks or hides authorization paths that full desktop environments usually provide.

2. **Bluetooth became persistently soft-blocked**
   - Current rfkill state showed `Soft blocked: yes`.
   - Persisted systemd-rfkill state also contained blocked state, so resets could reapply the problem.

## Durable fix pattern

For a Home Manager-managed Hyprland session:

- Install/include:
  - `bluez`
  - `blueman`
  - `lxqt.lxqt-policykit`
- Autostart:
  - `blueman-applet`
  - `lxqt-policykit-agent`
- If launcher PATH is unreliable, launch GUI tools from the Home Manager profile path.

For rfkill repair, after confirming the rfkill node belongs to Bluetooth:

```bash
sudo rfkill unblock bluetooth
sudo sh -c 'printf 0 > /var/lib/systemd/rfkill/<bluetooth-state-file>'
sudo sh -c 'printf 0 > /sys/class/rfkill/rfkillX/soft'
```

Then verify:

```bash
rfkill list bluetooth
bluetoothctl power on
bluetoothctl pairable on
bluetoothctl show
bluetoothctl scan on
```

## Evidence that hardware/driver was unlikely primary cause

- Adapter enumerated normally.
- BlueZ recognized the controller.
- Kernel logs did not show persistent firmware load failures or HCI reset loops.
- Scanning found multiple nearby BLE devices with plausible RSSI after unblocking.

## Device-specific follow-up

For keyboards such as Kinesis Adv360 Pro, put the keyboard into pairing mode and rediscover it. If a previously known address is unavailable, do not treat that as system Bluetooth failure; remove stale state and pair the newly discovered address.
