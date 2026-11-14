# Runtime diagnosis

## Desktop and editor

Wayland window position and focus requests are hints subject to compositor policy, not portable guarantees. In multi-viewport applications, target repaint at the intended viewport.

In eframe 0.34+, command handling belongs in `logic`, which can run after a repaint while the root is invisible; `ui` runs only for visible UI. In eframe 0.35, an immediate child can unmap between sparse parent passes when its root is hidden; an active child needs a ROOT-specific repaint after each parent pass. Closing the root normally ends `run_native`; cancel the close request when close means dismissal.

Linux `tray-icon` uses GTK, which eframe/winit does not pump; tray objects belong on a thread running the GTK main loop. On macOS, eframe/winit pumps AppKit, so create and retain the tray on the app's main thread.

Test a Waybar module in a live Wayland session: off-session startup failure or binary inspection does not establish whether the module is compiled in. An unknown-module error differs from an environment-gated disablement. Identify hwmon sensors by device identity and stable path, not transient numbering.

A Tree-sitter parser can attach while matching highlight queries are absent. Inspect installed parser and query paths and actual captures in a configured buffer; `nvim --headless --clean` removes plugin runtime paths and can give a misleading result.

## Hyprland lock and idle

If hyprlock rejects ordinary passwords, inspect its PAM service and fallback; an absent service can select a root-only fallback. Choose the PAM stack according to the host's authentication and lockout policy.

Monitor-off can leave only a fallback output without indicating lock failure; check `hyprctl locked -j`. Older Hyprland releases could crash when a key binding dispatched DPMS, then restart in safe mode with a minimal configuration; check the installed version and whether safe mode is active before diagnosing missing bindings.

Logind inhibitors can suppress hypridle actions. Inspect `systemd-inhibit --list` and the idle service journal; `ignore_systemd_inhibit` changes inhibitor policy and should be chosen deliberately, not confused with ignoring all listener inhibitors. Reloading a config file does not prove the idle daemon picked it up.

## Notebook and services

For fill-in-the-middle completions, inspect the rendered model input: an API success does not establish the correct prefix, suffix, or model-specific marker format. Monitor a shared kernel from a separate process when possible; an idle or exited kernel does not prove a cell succeeded, and monitoring does not establish that interruption is safe.

Mellum2 expects unpiped FIM markers: map marimo's piped markers to unpiped forms and render prefix + suffix + middle without chat framing. Native Qwen Chat-FIM recognizes marimo's piped markers; the Mellum2 remapping breaks its intended prompt. An OpenAI-compatible client may reject an empty API key; a non-whitespace placeholder satisfies validation but is not authentication.

A running service and deployed configuration do not prove the daemon parsed the intended rules. Check the resolved Home Manager output, systemd's parsed unit, and the daemon's own parsed state at their respective boundaries. A setting equal to its default cannot distinguish an applied value from an ignored one. Home Manager activation mutations must use the `run` helper to respect dry-run. For Hermes profile composition and ownership, consult `configs/hermes/README.md` in the dotfiles repository.

Nix `//` merges shallowly: replacing a nested attribute set can silently discard sibling settings. Git-backed flakes omit untracked files, so `git add` new inputs before evaluating a build when inclusion is intended.

## Credentials

A secret expanded into command arguments can be exposed in process listings; transfer and validate it through standard input or a protected file. For root-only credential files, `install -m 0600` sets restrictive permissions at creation; `tee` followed by `chmod` can leave an exposure window. The privileged command itself must open a root-only source when hashing, statting, or reading it: caller-shell redirection occurs before `sudo`.

SSH success or destination existence does not prove transfer integrity. Check nonempty length and full-digest equality, then exercise the consumer-equivalent read path without exposing the value.

## Skill packaging and discovery

A distributable `.skill` archive preserves the skill directory as its top-level entry. Validate relative references and exclude credentials, `.env`, `.git`, caches, and oversized artifacts. Search ranking or install counts alone are weak evidence for recommending a skill; review its source and evidence of adoption.

To see which skills a fresh session actually discovers, probe rather than trust a remembered directory map, for example `omp -p --mode json --no-session --tools=read '<ask it to list its skill names>'` and inspect assistant text events in the JSON stream. Check the installed CLI's options and output if its interface has changed.
