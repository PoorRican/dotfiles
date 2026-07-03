# Polybar tray vs StatusNotifier/AppIndicator bridge

When an app has a Linux tray/widget icon but it does not appear in Polybar, distinguish between two protocols:

- **XEmbed/system tray**: hosted directly by Polybar's `internal/tray` module.
- **StatusNotifierItem/AppIndicator (SNI)**: DBus-based protocol used by many modern apps; Polybar's tray does not host these directly.

Useful diagnostics in an X11+i3 session:

```bash
# Confirm Polybar has tray module loaded and is running
systemctl --user --no-pager --full status polybar.service
journalctl --user -u polybar.service --since "20 min ago" --no-pager | grep -Ei 'tray|warn|error|module'

# Confirm the bar config includes an internal tray
rg -n 'modules-right|\[module/tray\]|type = internal/tray' configs/polybar/config.ini

# Look for running bridge/watchers
ps -eo pid,comm,args | grep -E '(snixembed|xembedsniproxy|statusnotifier|appindicator)' | grep -v grep
busctl --user list | grep -Ei 'StatusNotifier|AppIndicator|indicator'
```

If Polybar's `internal/tray` is configured and loaded but a modern app's icon still does not appear, add a bridge such as `snixembed` and start it before tray-heavy apps:

```nix
home.packages = [ pkgs.snixembed ];
```

```i3
exec --no-startup-id snixembed
```

Then restart the affected app so it registers after the bridge is present.

JetBrains Toolbox is an example of an app where this can matter: it has a Linux tray icon, but on an i3/Polybar setup it may need SNI/AppIndicator bridging rather than just Polybar's native XEmbed tray module.

Additional pitfall observed on cbox/i3: Toolbox can log `Initialized StatusNotifierItem` while Polybar still shows no icon and `journalctl --user -u polybar.service` reports `tray: Failed to clear client(..., snixembed)` / `Failed to query _XEMBED_INFO` / `Failed to reconfigure client(..., snixembed)` with `XCB_WINDOW (3)`. In that state, repeated restarts of Toolbox/Polybar/snixembed are probably not enough; treat it as a bridge compatibility/architecture issue, verify visually with a root screenshot if possible, and prefer explicit app launchers/keybindings or a different SNI-capable tray/bar rather than relying solely on the invisible tray.
