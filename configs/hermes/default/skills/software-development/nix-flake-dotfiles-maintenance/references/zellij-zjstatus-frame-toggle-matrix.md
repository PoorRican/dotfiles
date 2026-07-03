# Zellij `zjstatus` frame-toggle regression matrix

Use this when debugging Zellij split-pane flicker/flashing in the user's Home Manager-managed dotfiles, especially with a custom `default_tab_template` status pane running `dj95/zjstatus`.

## Observed working/broken combinations

The flicker was reproduced on Zellij `0.44.3` with a custom layout containing a bottom `zjstatus` WASM pane and this combination:

```kdl
// config.kdl
pane_frames false
```

plus:

```kdl
// layouts/sourcerer-layout.kdl, inside the zjstatus plugin block
hide_frame_for_single_pane "true"
```

Disabling only `hide_frame_for_single_pane` while keeping global `pane_frames false` stopped the flicker:

```kdl
pane_frames false
// hide_frame_for_single_pane "true"
```

A later experiment tested the user's hypothesis that the bug is the *combination*, not necessarily `hide_frame_for_single_pane` alone:

```kdl
// pane_frames false
hide_frame_for_single_pane "true"
```

This should be treated as an experiment to preserve dynamic old behavior: Zellij frames use their default behavior globally, while `zjstatus` hides frames only for single-pane tabs.

## Do not overclaim

Do **not** state that `hide_frame_for_single_pane` is universally broken by itself unless the no-global-`pane_frames false` experiment also fails. The proven local fact was the matrix row:

| `pane_frames false` | `hide_frame_for_single_pane` | Result |
| --- | --- | --- |
| yes | yes | broken/flicker |
| yes | no | stable |
| no | yes | experiment; ask/test before concluding |
| no | no | likely stable but not the desired no-frame/dynamic behavior |

## Upstream signals

Relevant upstream issues at the time:

- `dj95/zjstatus#255`: reports `0.44.2 hide_frame_for_single_pane broken`, with a repro containing both `pane_frames false` and `hide_frame_for_single_pane "true"`.
- `zellij-org/zellij#5228`: reports plugin API `toggle_pane_frames()` being reverted by Zellij within split seconds, affecting `zjstatus`/`zjframes` frame hiding behavior.

## Workflow for future sessions

1. Preserve the custom layout first; do not immediately replace it with built-in `compact` unless isolation requires it.
2. Validate KDL with:
   ```bash
   ZELLIJ_CONFIG_DIR=/home/swe/dotfiles/configs/zellij zellij setup --check
   ```
3. Apply via Home Manager only after staging intended Zellij files so the flake sees them:
   ```bash
   cd /home/swe/dotfiles
   git add configs/zellij/config.kdl configs/zellij/layouts/sourcerer-layout.kdl
   nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
   home-manager switch --flake .#cbox
   ```
4. Verify the live symlinked files under `~/.config/zellij/` contain the intended matrix row before asking the user to test a fresh Zellij session.
5. Do not kill existing Zellij sessions automatically unless the user explicitly accepts losing pane state.

## Quick revert pattern

If the dynamic-frame experiment flickers, restore the known stable row:

```kdl
// config.kdl
pane_frames false
```

and inside the `zjstatus` plugin block:

```kdl
// hide_frame_for_single_pane "true"
```
