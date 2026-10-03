# Desktop and editor apps

Scope: Platform, event-loop, and runtime-discovery behavior for native desktop applications and editor plugins.

## Native popup event loops

- In eframe 0.34+, `App::update` is removed: command handling belongs in `logic`, which can run after a repaint while the root is invisible, whereas `ui` runs only for visible UI. A command that reveals a hidden root cannot depend on `ui` to receive it. (src: egui-native-popup-integration; 2026-07-21)
- eframe 0.35 can unmap an immediate child between sparse parent passes when its ROOT host is hidden; an active child therefore needs a ROOT-specific repaint after each parent pass to preserve input continuity. (src: egui-native-popup-integration; 2026-07-21)
- In a multi-viewport app, a background `request_repaint()` can target the wrong viewport; waking the stable ROOT viewport avoids depending on whichever child was most recently active. (src: egui-native-popup-integration; 2026-07-21)
- Linux `tray-icon` uses GTK, which eframe/winit does not pump; tray objects belong on a thread running the GTK main loop. On macOS, eframe/winit pumps AppKit, so the tray is created and retained on the app's main thread rather than by copying the Linux thread arrangement. (src: egui-native-popup-integration; 2026-07-21)
- Wayland does not guarantee a client-selected global window position or keyboard focus; position and focus requests are hints subject to compositor policy, not portable guarantees. (src: egui-native-popup-integration; 2026-07-21)
- Closing an eframe root normally ends `run_native`; when close means dismissal rather than process exit, the close request must be canceled and converted into a dismiss outcome. (src: egui-native-popup-integration; 2026-07-21)

## Waybar module capability

- Binary inspection (`ldd`, package metadata, or strings) is inconclusive about whether a Waybar module is compiled in; only instantiation in a live Wayland session separates missing build support from an environmental disablement. (src: waybar-module-runtime-check; 2026-09-04)
- Waybar exits before configuration when there is no live Wayland session, so an off-session probe cannot establish module capability. “Unknown module” indicates a missing build capability, while another disable reason can indicate an environment-gated module. (src: waybar-module-runtime-check; 2026-09-04)
- Hwmon numbering can change across boots, so stable sensor identity comes from its device name and stable path rather than a transient numbered directory. (src: waybar-module-runtime-check; 2026-09-04)

## Neovim parser and query mismatch

- A legacy parser file can satisfy `get_parser` and attach a Tree-sitter highlighter while current main-branch highlight queries are absent, leaving a plain-text buffer; parser attachment alone does not establish usable highlighting. (src: nvim-treesitter-main-no-highlight-triage; 2026-09-06)
- `nvim --headless --clean` strips plugin runtime and package paths, so missing plugins or zero parser counts from that probe can be artifacts rather than the configured editor's state. (src: nvim-treesitter-main-no-highlight-triage; 2026-09-06)
- The orphan-parser signature is established by the installed-language list, parser and query runtime-file paths, and actual query captures in a real buffer; an active-highlighter flag or install message alone cannot establish that highlight queries produce captures. (src: nvim-treesitter-main-no-highlight-triage; 2026-09-06)
- The `main` branch installs parsers and `.scm` queries under the site runtime directory; in the orphan-parser case, the old plugin-checkout parser and its parser-info revision can shadow that managed install. (src: nvim-treesitter-main-no-highlight-triage; 2026-09-06)

## Input daemon stream observations

- `drift-inputd` is newest-client-wins: even a read-only socket probe displaces the active Drift client, so a probe connection changes the system being observed. (src: drift-input-daemon-artifact-validation; 2026-07-29)
- An active stream associated with the running Drift process is not expected to contain Arrow EOS until normal shutdown; absence of EOS on that active stream alone is not evidence of truncation. (src: drift-input-daemon-artifact-validation; 2026-07-29)
- A concurrently appended Arrow file should be interpreted from one fixed byte snapshot; a newly orphaned screenshot can be an in-flight flush race, so a later stable snapshot is needed before classifying it as defective. (src: drift-input-daemon-artifact-validation; 2026-07-29)

