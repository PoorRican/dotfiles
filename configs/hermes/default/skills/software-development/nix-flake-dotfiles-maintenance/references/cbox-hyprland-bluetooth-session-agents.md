# cbox Hyprland Bluetooth GUI/session-agent workflow

Session pattern from diagnosing Blueman connection failures on cbox/Hyprland.

## Symptoms

- `blueman-manager` opens from Waybar but cannot reliably connect/pair Bluetooth devices.
- `blueman-applet.service` is inactive or not autostarted in the Hyprland session.
- `polkitd` is running, but no user-session Polkit authentication agent is running.
- BlueZ and the adapter look healthy: `rfkill` clear, controller powered, `bluetoothctl scan on` discovers devices with reasonable RSSI, and kernel logs do not show firmware/reset loops.
- A specific BLE HID device (for example Kinesis Adv360 Pro) may show repeated BlueZ GATT/profile errors or stale pairing state, but the controller can still scan nearby devices.

## Diagnostic commands

```bash
systemctl --no-pager --full status bluetooth.service
rfkill list
bluetoothctl list
bluetoothctl show
bluetoothctl scan on
bluetoothctl devices
bluetoothctl info <MAC>
journalctl -u bluetooth -b --no-pager | tail -260
journalctl --user --since '2 days ago' --no-pager | grep -Ei 'blueman|bluez|bluetooth|polkit|policykit'
pgrep -af 'blueman|polkit|policy|waybar|Hyprland|nm-applet|dunst'
command -v blueman-manager blueman-applet lxqt-policykit-agent polkit-gnome-authentication-agent-1
pacman -Q blueman bluez bluez-utils polkit 2>&1 || true
```

For adapter identity and driver health:

```bash
readlink -f /sys/class/bluetooth/hci0/device
udevadm info -q property -p "$(readlink -f /sys/class/bluetooth/hci0/device)"
btmgmt info
hciconfig -a
journalctl -k -b --no-pager | grep -Ei 'bluetooth|btusb|hci0|firmware|qca|qualcomm|reset' | tail -200
```

## Interpretation

If scanning finds nearby devices with moderate/strong RSSI (for example around `-50 dBm`) and the controller remains powered, do not jump to “bad antenna” or “bad driver.” Treat the problem as higher-layer session integration unless kernel logs show adapter resets/firmware failures.

In a custom Hyprland session, launching only `blueman-manager` is not enough. Blueman expects its applet/tray/agent process to be alive for normal desktop flows, and GUI tools often need a user-session Polkit auth agent in addition to system `polkitd`.

## Durable Home Manager / Hyprland pattern

In the cbox Hyprland Home Manager module, include:

```nix
home.packages = with pkgs; [
  blueman
  bluez
  lxqt.lxqt-policykit
];
```

In `configs/hypr/hyprland.lua`, autostart both session agents on `hyprland.start`:

```lua
hl.exec_cmd(hmBin .. "/blueman-applet")
hl.exec_cmd(hmBin .. "/lxqt-policykit-agent")
```

Keep Waybar’s Bluetooth click path inside the Home Manager profile instead of hardcoding `/usr/bin` when Blueman is HM-managed:

```jsonc
"bluetooth": {
  "on-click": "/home/swe/.local/state/nix/profiles/home-manager/home-path/bin/blueman-manager"
}
```

Verify with:

```bash
luac -p configs/hypr/hyprland.lua
python - <<'PY'
from pathlib import Path
import json
# Strip // comments outside strings for this simple JSONC shape.
s = Path('configs/waybar/config.jsonc').read_text()
out=[]; in_str=False; esc=False; i=0
while i < len(s):
    ch=s[i]
    if in_str:
        out.append(ch)
        if esc: esc=False
        elif ch == '\\': esc=True
        elif ch == '"': in_str=False
        i += 1
    elif ch == '"':
        in_str=True; out.append(ch); i += 1
    elif ch == '/' and i+1 < len(s) and s[i+1] == '/':
        while i < len(s) and s[i] != '\n': i += 1
    else:
        out.append(ch); i += 1
json.loads(''.join(out))
PY
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
home-manager switch --flake .#cbox --no-write-lock-file
```

After applying, either restart Hyprland or live-start for the current session:

```bash
systemctl --user start blueman-applet.service
hyprctl eval 'hl.exec_cmd(os.getenv("HOME") .. "/.local/state/nix/profiles/home-manager/home-path/bin/lxqt-policykit-agent")'
```

Then confirm:

```bash
pgrep -af 'blueman-applet|blueman-tray|lxqt-policykit-agent'
journalctl --user --since '2 minutes ago' --no-pager | grep -Ei 'blueman|policykit|polkit|lxqt'
```

## BLE HID cleanup still applies

If a particular keyboard/mouse still fails after the session agents are running, fall back to direct BlueZ pairing rather than repeatedly clicking Blueman:

```text
bluetoothctl --agent KeyboardDisplay
power on
agent KeyboardDisplay
default-agent
pairable on
remove <MAC>
scan on
pair <MAC>
trust <MAC>
connect <MAC>
```

If the keyboard displays or requires a passkey, type it on the device being paired and press Enter on that device.
