# Hermes Agent — config + package installation via upstream flake
# Symlinks non-config profile files from configs/hermes/<profile>/ into ~/.hermes/
# and deep-merges Nix-managed baseline settings into ~/.hermes/config.yaml.
{ config, lib, pkgs, dotfiles, inputs, ... }:
let
  cfg = config.programs.hermes;
  profileSrc = dotfiles + "/configs/hermes/${cfg.profile}";
  dotfilesPath = "${config.home.homeDirectory}/dotfiles/configs/hermes/${cfg.profile}";
  entries = builtins.readDir profileSrc;
  upstreamHermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  defaultExtras = [
    "dev"
    # Discord gateway support is enabled in config, and Nix-managed installs can't
    # rely on Hermes lazy-installing Python deps at first use.
    "messaging"
    # Hermes 0.12 makes croniter a core dependency and leaves the cron extra empty.
    # uv2nix/pyproject-nix omit empty extras from uv.lock, so requesting "cron"
    # makes virtualenv resolution fail even though runtime cron support is present.
    "cli"
    "pty"
    # `dev` already pulls `mcp`, but keep it explicit because local MCP servers are
    # a core part of this repo's Hermes workflow.
    "mcp"
    "homeassistant"
    "acp"
    "web"
  ];
  profileConfigPath = profileSrc + "/config.nix";
  profileSettings = if builtins.pathExists profileConfigPath then import profileConfigPath { inherit lib; } else {};
  linkedEntries = lib.filterAttrs (name: _type: !(builtins.elem name [ "config.yaml" "config.nix" ])) entries;
  settingsJson = pkgs.writeText "hermes-settings.json" (builtins.toJSON cfg.settings);
  mergeHermesConfig = pkgs.writeScript "hermes-config-merge" ''
    #!${pkgs.python3.withPackages (ps: [ ps.pyyaml ])}/bin/python3
    import json, yaml, sys, tempfile, os
    from pathlib import Path

    nix_json, config_path = sys.argv[1], Path(sys.argv[2])

    with open(nix_json) as f:
        nix = json.load(f)

    existing = {}
    if config_path.exists():
        with open(config_path) as f:
            existing = yaml.safe_load(f) or {}

    def deep_merge(base, override):
        result = dict(base)
        for k, v in override.items():
            if k in result and isinstance(result[k], dict) and isinstance(v, dict):
                result[k] = deep_merge(result[k], v)
            else:
                result[k] = v
        return result

    merged = deep_merge(existing, nix)
    config_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile('w', delete=False, dir=str(config_path.parent)) as tmp:
        yaml.safe_dump(merged, tmp, default_flow_style=False, sort_keys=False)
        temp_name = tmp.name
    os.replace(temp_name, config_path)
  '';
in {
  options.programs.hermes = {
    enable = lib.mkEnableOption "Hermes Agent";
    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Hermes config profile directory under configs/hermes/.";
    };
    extras = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultExtras;
      description = "Hermes extras preinstalled via the upstream package override.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = upstreamHermesPackage;
      description = "Hermes package to install. Defaults to the repo-standard custom build when enabled.";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = profileSettings;
      description = "Baseline Hermes configuration merged into ~/.hermes/config.yaml.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hermes.package = lib.mkDefault (upstreamHermesPackage.override {
      extraDependencyGroups = cfg.extras;
    });

    home.packages = [ cfg.package ];

    home.file = lib.mapAttrs' (name: _type:
      lib.nameValuePair ".hermes/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${name}";
      }
    ) linkedEntries;

    home.activation.mergeHermesConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeHermesConfig} ${settingsJson} ${config.home.homeDirectory}/.hermes/config.yaml
    '';
  };
}
