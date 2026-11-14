# Interactive UI testing

Terminal output can contain ANSI, OSC, and APC sequences around visible text; normalize captures before matching and wait for observed readiness rather than relying on a fixed startup delay. To test a state transition, inspect fresh output after the action: stale screen text may satisfy an assertion without the action having succeeded.

A graphical application needs a compositor, not just a PTY. For isolated Wayland smoke tests use a private runtime directory, session bus, headless compositor, notification daemon, and synthetic data; never change the user's desktop configuration for a smoke. Discover executable paths instead of copying transient store paths. Inspect the actual client rectangle before injecting input, and verify the resulting state rather than only window closure. Synthetic input is not a human-click test.

For a headless wlroots compositor, use `WLR_BACKENDS=headless`, `WLR_RENDERER=pixman`, and `WLR_LIBINPUT_NO_DEVICES=1`. Set `DISPLAY` to an invalid value if an unset display causes the app's clipboard integration to stall attempting X11. Use a fixed output size and inspect the actual client rectangle; a stable notification position and no timeout make clicks deterministic.

One-shot virtual-pointer processes can drop the seat capability before a notification receives the click. Keep one virtual-pointer connection alive through motion, press, release, and verification. Confirm a notification belongs to the scenario before clicking; an action invoked directly over D-Bus proves routing, not pointer dispatch. Accelerated timer tests do not prove real wall-clock behavior.

With `zwlr_virtual_pointer_manager_v1`, send absolute motion using the output's real dimensions, frame and roundtrip, then press and release on the same connection. Hold keyboard modifiers around the key with small delays, and verify persisted exact content, not merely that a window closed.

A sandboxed nested compositor may render no frames if its libseat session remains inactive; diagnose its seat and device access within the sandbox rather than changing the production session. A read-only connection to a newest-client-wins input socket can displace the active client: use a fake authorized socket to test such protocols. Before restarting a live app, check current mode and unsaved work; do not launch unsolicited prompts on the user's desktop.
