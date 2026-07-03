# Host-Specific Overlay Example

## Session pattern

Problem: a macOS-only overlay (`imsg-overlay`) was declared as a top-level flake input in a shared dotfiles repo:

```nix
inputs.imsg-overlay = {
  url = "path:/Users/swe/repos/imsg-overlay";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Even though only `homeConfigurations.mbp` used it, Linux hosts still inherited a global dependency on a Darwin-local path.

## Fix used

1. Remove `imsg-overlay` from `inputs` in `flake.nix`
2. Remove the stale `imsg-overlay` node from `flake.lock`
3. Replace direct input usage with a local binding inside `outputs`:

```nix
outputs = { nixpkgs, home-manager, hermes-agent, ... }@inputs:
let
  imsgOverlay = (builtins.getFlake "path:/Users/swe/repos/imsg-overlay").overlays.default;
in {
  homeConfigurations.mbp = mkHome {
    system = "aarch64-darwin";
    overlays = [ darwinTestFixesOverlay imsgOverlay ];
  };
}
```

## Why this helped

- Linux host evaluation no longer depended on a macOS-local path entry in the global flake graph
- The overlay remained available for the only host that needed it (`mbp`)
- The fix was minimal: no unrelated flake restructuring

## Verification used

```bash
nix eval '.#homeConfigurations.emc.activationPackage.drvPath' --no-write-lock-file
nix eval '.#homeConfigurations.cbox.activationPackage.drvPath' --no-write-lock-file
nix eval '.#homeConfigurations.dgx.activationPackage.drvPath' --no-write-lock-file
```

All three Linux evaluations succeeded after the change.

## Caution

This pattern still assumes the target macOS machine has `/Users/swe/repos/imsg-overlay` available when `mbp` is evaluated. That is acceptable when the goal is only to keep non-macOS hosts independent of the overlay.
