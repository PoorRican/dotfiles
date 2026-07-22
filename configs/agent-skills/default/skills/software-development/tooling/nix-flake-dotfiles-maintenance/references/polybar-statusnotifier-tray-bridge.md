# Polybar tray bridge for StatusNotifier/AppIndicator apps

Context: cbox/i3 uses Polybar with an `internal/tray` module. Apps such as JetBrains Toolbox may expose their tray icon via the DBus StatusNotifier/AppIndicator protocol rather than the older XEmbed system tray protocol.

## Durable lesson

Polybar's `internal/tray` hosts XEmbed tray icons. If an app is running but its tray icon does not appear, and the Polybar tray module is loaded, check whether the session has a StatusNotifier/AppIndicator-to-XEmbed bridge running.

A practical bridge in nixpkgs is `snixembed`.

## Dotfiles pattern

Add the package in the i3 desktop Home Manager module:

```nix
home.packages = with pkgs; [
  # ...
  networkmanagerapplet
  snixembed
  picom
  # ...
];
```

Start it from i3 before tray-heavy apps:

```i3
# Bridge StatusNotifier/AppIndicator tray icons into Polybar's XEmbed tray.
exec --no-startup-id snixembed
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
```

After applying, restart i3/session or run `snixembed &` manually, then restart the app whose icon was missing so it can re-register its tray item.

## Verification pattern

- Confirm Polybar config includes `type = internal/tray` and the module is present in `modules-*`.
- Confirm Polybar logs loaded `module 'tray'`.
- Confirm the app process is running.
- Look for a bridge process such as `snixembed` or `xembedsniproxy` when SNI/AppIndicator apps do not show.
- Run `i3 -C -c configs/i3/config` and `nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file` after dotfiles edits.
