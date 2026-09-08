# Hermes Agent — upstream package plus a thin multi-profile Home Manager adapter.
#
# Nix owns declared configuration: config.yaml (replaced on each activation,
# never merged), SOUL.md, extra files, the immutable skill view, cron job
# definitions, launchers and gateway units. seedFiles initializes missing
# runtime files only; existing memories and other runtime state are preserved.
# Credentials (.env, auth.json) must never be included in store-backed sources.
#
# `profiles.default` is the root home (~/.hermes). Every other attribute name
# is a real Hermes named profile at ~/.hermes/profiles/<name>, reachable with
# `hermes -p <name>` and the `~/.local/bin/<name>` launcher.
#
# Another flake can extend a host by importing the same options, for example
#   dotfiles.homeConfigurations.wst.extendModules { modules = [ ./private.nix ]; }
# and declaring `programs.hermes.profiles.<name>` there, including private
# skill roots. See configs/hermes/README.md.
{ config, lib, pkgs, dotfiles, inputs, ... }:
let
  cfg = config.programs.hermes;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  skillsLib = import ../lib/agent-skills.nix { inherit lib pkgs; };
  agentSkills = config.programs.agent-skills;
  collections = import (dotfiles + "/configs/agent-skills/collections.nix");
  hostCollections = lib.attrByPath [ "hosts" agentSkills.host ] { coding = [ ]; hermes = [ ]; } collections;

  upstreamPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  sitePackages = pkgs.python312.sitePackages;

  # Hermes' pyproject py-modules list lags the top-level modules its own code
  # imports (hermes_state_holders and hermes_state_registry as of 0.21), so the
  # sealed uv2nix venv omits them. Ship whichever top-level modules the venv
  # lacks; once upstream lists them all this directory is empty.
  missingTopLevelModules = venv: pkgs.runCommand "hermes-missing-modules" { } ''
    site="$out/${sitePackages}"
    mkdir -p "$site"
    for module in ${inputs.hermes-agent}/*.py; do
      name="$(basename "$module")"
      [ "$name" = setup.py ] && continue
      if [ ! -e "${venv}/${sitePackages}/$name" ]; then
        install -m 0444 "$module" "$site/$name"
      fi
    done
  '';
  withMissingModules = package:
    let
      shim = missingTopLevelModules package.hermesVenv;
    in
      package.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postFixup = (old.postFixup or "") + ''
          for program in hermes hermes-agent hermes-acp; do
            wrapProgram "$out/bin/$program" --suffix PYTHONPATH : "${shim}/${sitePackages}"
          done
        '';
        passthru = (old.passthru or { }) // { moduleShim = shim; };
      });

  defaultExtras = [
    "dev"
    # Discord gateway support; Nix-managed installs can't lazy-install Python deps.
    "messaging"
    # `dev` already pulls `mcp`; keep it explicit because local MCP servers are
    # a core part of this repo's Hermes workflow.
    "mcp"
    "homeassistant"
    "acp"
    "web"
  ];

  # Interpreter that sees the sealed venv plus the module shim; used for the
  # build-time renderer and the activation-time cron reconciler. A custom
  # `package` must expose the upstream `hermesVenv` passthru.
  venvPython = "${cfg.package.hermesVenv}/bin/python3";
  pythonPathEnv = "PYTHONPATH=${lib.optionalString (cfg.package ? moduleShim) "${cfg.package.moduleShim}/${sitePackages}"}";

  # Attribute sets from several module definitions merge per key, so a host or
  # an extending flake can add one key without restating the whole profile.
  # Conflicting leaves must be resolved explicitly with lib.mkForce.
  settingsType = lib.types.attrsOf lib.types.anything;

  fileSource = lib.types.either lib.types.str lib.types.path;

  pathsOverlap = a: b: a == b || lib.hasPrefix "${a}/" b || lib.hasPrefix "${b}/" a;

  cronJobType = lib.types.submodule {
    options = {
      schedule = lib.mkOption {
        type = lib.types.str;
        description = "Cron expression, interval (\"every 30m\") or ISO timestamp, as `hermes cron create` accepts.";
        example = "0 7 * * 1-5";
      };
      prompt = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Self-contained task prompt. May be omitted when skills or a script carry the job.";
      };
      skills = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Skills loaded before the prompt runs.";
      };
      deliver = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Delivery target (\"local\", \"discord:#channel\", \"telegram:<chat>\", …). Defaults to local.";
      };
      model = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Per-job model override.";
      };
      provider = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Per-job provider override.";
      };
      base_url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Per-job base URL override.";
      };
      script = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Script whose stdout feeds the job; relative paths resolve under $HERMES_HOME/scripts.";
      };
      enabled_toolsets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Restrict the job to these toolsets. Empty means the profile default.";
      };
      workdir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Absolute working directory for the job.";
      };
      no_agent = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run only the script and deliver its stdout; no model call.";
      };
      reasoning_effort = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Per-job reasoning effort pin.";
      };
      repeat = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Number of runs; null repeats forever.";
      };
      failure_deliver = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Delivery target for failed runs.";
      };
      monitor_script = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Monitor script; the agent runs only when its output changes.";
      };
      monitor_url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Monitor URL; the agent runs only when its content changes.";
      };
      context_from = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Job IDs whose latest output is injected as context.";
      };
    };
  };

  profileType = lib.types.submodule ({ name, ... }: {
    options = {
      enable = lib.mkEnableOption "this Hermes profile" // { default = true; };

      home = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "HERMES_HOME of this profile.";
      };

      settings = lib.mkOption {
        type = settingsType;
        default = { };
        description = ''
          Complete non-secret config.yaml for the profile. Only deviations from
          the Hermes defaults belong here; the file on disk is replaced on every
          activation, so removing a key here removes it from the profile.
        '';
      };

      soul = lib.mkOption {
        type = lib.types.nullOr fileSource;
        default = null;
        description = "SOUL.md content or path. Null leaves Hermes' seeded SOUL.md alone.";
      };

      files = lib.mkOption {
        type = lib.types.attrsOf fileSource;
        default = { };
        description = "Extra Nix-owned files replaced on every activation below HERMES_HOME (mode 0600). Use seedFiles for runtime-owned initial snapshots.";
        example = lib.literalExpression ''{ "instructions.txt" = ./instructions.txt; }'';
      };

      seedFiles = lib.mkOption {
        type = lib.types.attrsOf fileSource;
        default = { };
        description = ''
          Initial snapshots for runtime-owned files, keyed by relative path.
          Only absent files are seeded (mode 0600); existing files are never
          overwritten or removed. Activation reports matches and differences;
          verbose activation also prints a snapshot-to-runtime text diff.
          Parent directories, including home ancestors, must not be symlinks.
          Sources enter the Nix store: do not include secrets.
        '';
        example = lib.literalExpression ''{ "memories/USER.md" = ./USER.md; }'';
      };

      skills = {
        roots = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "Extra categorized skill roots for this profile, searched together with programs.agent-skills.catalogRoots.";
        };
        names = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Skill names published to this profile as an immutable external directory.";
        };
        allowBundled = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Let Hermes seed its bundled skills into the mutable skills directory.";
        };
      };

      cron.jobs = lib.mkOption {
        type = lib.types.attrsOf cronJobType;
        default = { };
        description = "Cron jobs reconciled into the profile's cron/jobs.json, keyed by job name.";
      };

      gateway.enable = lib.mkEnableOption "the messaging gateway service for this profile";

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Packages on the gateway's PATH in addition to the user's profile.";
      };

      alias = lib.mkOption {
        type = lib.types.bool;
        default = name != "default";
        description = "Install ~/.local/bin/<name> so the profile runs as `<name> chat`.";
      };
    };

    config.home =
      if name == "default" then cfg.root else "${cfg.root}/profiles/${name}";
  });

  enabledProfiles = lib.filterAttrs (_: profile: profile.enable) cfg.profiles;

  # ── Per-profile build products ────────────────────────────────────────────
  profileCatalog = profile: skillsLib.mkCatalog (agentSkills.catalogRoots ++ profile.skills.roots);

  skillView = name: profile:
    skillsLib.mkCategorizedView {
      name = "hermes-${name}";
      skills = (profileCatalog profile).select profile.skills.names;
    };

  # Skill view first so the store path is part of the rendered settings.
  effectiveSettings = name: profile:
    lib.recursiveUpdate profile.settings {
      skills.external_dirs = [ (toString (skillView name profile)) ];
    };

  configFile = name: profile:
    pkgs.runCommand "hermes-config-${name}.yaml"
      {
        settingsJson = builtins.toJSON (effectiveSettings name profile);
        passAsFile = [ "settingsJson" ];
      } ''
        export HERMES_HOME="$TMPDIR/hermes-home"
        export ${pythonPathEnv}
        ${venvPython} ${./hermes/render-config.py} "$settingsJsonPath" "$out"
      '';

  documentTree = name: documents:
    pkgs.runCommand "hermes-files-${name}" { } (
      ''
        mkdir -p "$out"
      ''
      + lib.concatStringsSep "\n" (lib.mapAttrsToList (relative: value: ''
        destination="$out"/${lib.escapeShellArg relative}
        mkdir -p "$(dirname "$destination")"
        ${if builtins.isPath value || lib.isStorePath value
          then ''cp ${lib.escapeShellArg "${value}"} "$destination"''
          else ''cp ${pkgs.writeText "hermes-file" value} "$destination"''}
      '') documents)
    );

  cronSpec = name: profile:
    pkgs.writeText "hermes-cron-${name}.json" (builtins.toJSON (
      lib.mapAttrs (_: job: lib.filterAttrs (_: value: value != null) job) profile.cron.jobs
    ));

  # ── Activation ────────────────────────────────────────────────────────────
  # Everything below goes through `run` so `home-manager switch --dry-run`
  # only prints. Files are copies with owner-only modes (executables keep
  # their bit): Hermes rejects a store symlink for config.yaml and a
  # shared-readable credential directory.
  profileActivation = name: profile:
    let
      home = lib.escapeShellArg profile.home;
      documents = profile.files // lib.optionalAttrs (profile.soul != null) { "SOUL.md" = profile.soul; };
      tree = documentTree name documents;
      seeds = documentTree "${name}-seeds" profile.seedFiles;
      marker = lib.escapeShellArg profile.home + "/.no-bundled-skills";
    in ''
      # ${name}: ${profile.home}
      run mkdir -p ${home} ${lib.concatMapStringsSep " " (d: "${home}/${d}") [ "cron" "sessions" "logs" "memories" "plugins" "skills" ]}
      run chmod 0700 ${home}
      ${lib.optionalString (name != "default") ''
        # A profile deleted through Hermes leaves a tombstone that blocks reuse.
        run rm -f ${lib.escapeShellArg "${cfg.root}/profiles/.deleted/${name}"}
      ''}
      run install -m 0600 ${configFile name profile} ${home}/config.yaml
      run install -m 0600 ${pkgs.writeText "hermes-managed" "home-manager"} ${home}/.managed
      ${if profile.skills.allowBundled then ''
        run rm -f ${marker}
      '' else ''
        run install -m 0600 ${pkgs.writeText "hermes-no-bundled-skills" ''
          This profile is managed by Nix; its skills come from an immutable external
          directory. Remove this file only through programs.hermes.profiles.${name}.skills.allowBundled.
        ''} ${marker}
      ''}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (relative:
        let
          source = "${tree}/${lib.escapeShellArg relative}";
        in _: ''
          if [ -x ${source} ]; then mode=0700; else mode=0600; fi
          run install -m "$mode" -D ${source} ${home}/${lib.escapeShellArg relative}
        ''
      ) documents)}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (relative: _:
        let
          command = "${venvPython} ${dotfiles + "/scripts/hermes/seed-file.py"} ${lib.escapeShellArg "${seeds}/${relative}"} ${lib.escapeShellArg "${profile.home}/${relative}"}";
        in ''
          if [[ -v DRY_RUN ]]; then
            # Read-only comparison still runs during dry-run, including diffs.
            ${command} --dry-run ''${VERBOSE+--verbose}
          else
            run ${command} ''${VERBOSE+--verbose}
          fi
        ''
      ) profile.seedFiles)}
      run env HERMES_HOME=${home} HERMES_MANAGED=home-manager ${pythonPathEnv} \
        ${venvPython} ${./hermes/reconcile-cron.py} ${cronSpec name profile}
    '';

  # ── Gateway services ──────────────────────────────────────────────────────
  unitSuffix = name: lib.optionalString (name != "default") "-${name}";
  gatewayArgv = name: [ "${cfg.package}/bin/hermes" ]
    ++ lib.optionals (name != "default") [ "-p" name ]
    ++ [ "gateway" "run" ];
  homeDir = config.home.homeDirectory;
  gatewayPath = profile: lib.concatStringsSep ":" [
    "${homeDir}/.local/state/nix/profiles/home-manager/home-path/bin"
    "${homeDir}/.local/bin"
    (lib.makeBinPath ([ cfg.package pkgs.bash pkgs.coreutils pkgs.git ] ++ profile.extraPackages))
    "/run/current-system/sw/bin"
    "/etc/profiles/per-user/${config.home.username}/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
  ];
  gatewayEnvironment = profile: {
    HERMES_HOME = profile.home;
    HERMES_MANAGED = "home-manager";
    HERMES_SUPERVISED_CHILD = "1";
    PATH = gatewayPath profile;
  };
  # Mirrors hermes_cli.gateway: TimeoutStopSec must cover the longer of the
  # chat drain and the cron drain (+10s cleanup), plus 30s headroom, 60s floor.
  gatewayStopTimeout = profile:
    let
      agent = profile.settings.agent or { };
      drain = agent.restart_drain_timeout or 0;
      cron = agent.cron_drain_timeout or 30;
      cronBudget = if cron > 0 then cron + 10 else 0;
    in
      lib.max 60 (lib.max drain cronBudget + 30);

  gatewayProfiles = lib.filterAttrs (_: profile: profile.gateway.enable) enabledProfiles;

  systemdUnits = lib.mapAttrs' (name: profile:
    lib.nameValuePair "hermes-gateway${unitSuffix name}" {
      Unit = {
        Description = "Hermes Agent Gateway (${name})";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs (gatewayArgv name);
        WorkingDirectory = profile.home;
        Environment = lib.mapAttrsToList (k: v: "${k}=${v}") (gatewayEnvironment profile);
        Restart = "always";
        RestartSec = 5;
        RestartForceExitStatus = 75;
        RestartPreventExitStatus = 78;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
        TimeoutStopSec = gatewayStopTimeout profile;
        UMask = "0077";
      };
      Install.WantedBy = [ "default.target" ];
    }) gatewayProfiles;

  launchdAgents = lib.mapAttrs' (name: profile:
    lib.nameValuePair "hermes-gateway${unitSuffix name}" {
      enable = true;
      config = {
        Label = "org.nix-community.home.hermes-gateway${unitSuffix name}";
        ProgramArguments = gatewayArgv name;
        EnvironmentVariables = gatewayEnvironment profile;
        WorkingDirectory = profile.home;
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 5;
        StandardOutPath = "${homeDir}/Library/Logs/hermes-gateway${unitSuffix name}.log";
        StandardErrorPath = "${homeDir}/Library/Logs/hermes-gateway${unitSuffix name}.err.log";
        ProcessType = "Background";
      };
    }) gatewayProfiles;

  managedUnitFiles = lib.concatMapStringsSep " "
    (name: lib.escapeShellArg "${homeDir}/.config/systemd/user/hermes-gateway${unitSuffix name}.service")
    (lib.attrNames gatewayProfiles);
in {
  imports = [ ./agent-skills.nix ];

  options.programs.hermes = {
    enable = lib.mkEnableOption "Hermes Agent";

    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.hermes";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.hermes"'';
      description = "Hermes root: the default profile's HERMES_HOME and the parent of profiles/.";
    };

    extras = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultExtras;
      description = "pyproject dependency groups sealed into the venv.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "Hermes package to install; defaults to the upstream flake package with `extras` and the module repair applied.";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf profileType;
      default = { };
      description = "Hermes profiles. `default` is ~/.hermes; any other name is ~/.hermes/profiles/<name>.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hermes.package = lib.mkDefault (withMissingModules (
      upstreamPackage.override { extraDependencyGroups = cfg.extras; }
    ));

    # The default profile carries the dotfiles policy; hosts and extending
    # flakes add to it or declare named profiles beside it.
    programs.hermes.profiles.default = {
      settings = import (dotfiles + "/configs/hermes/default/config.nix") { inherit lib; };
      soul = dotfiles + "/configs/hermes/default/SOUL.md";
      skills.names = lib.unique (
        collections.coding ++ hostCollections.coding ++ collections.hermes ++ hostCollections.hermes
      );
    };

    assertions = lib.concatLists (lib.mapAttrsToList (name: profile:
      let
        catalog = profileCatalog profile;
        label = "programs.hermes.profiles.${name}";
        seedPaths = lib.attrNames profile.seedFiles;
        # files may spell the same target with ./ or repeated separators.
        ownedPaths = map (path: lib.removePrefix "./" (lib.path.subpath.normalise path)) (
          [ "config.yaml" ".managed" ".no-bundled-skills" "cron/jobs.json" ]
          ++ lib.optional (name == "default") "profiles"
          ++ lib.attrNames profile.files
          ++ lib.optional (profile.soul != null) "SOUL.md"
        );
      in
        skillsLib.catalogAssertions { inherit catalog label; }
        ++ [
          (skillsLib.selectionAssertion { inherit catalog label; names = profile.skills.names; })
          {
            assertion = builtins.match "[A-Za-z0-9][A-Za-z0-9_-]*" name != null;
            message = "${label}: profile names must be alphanumeric with - or _";
          }
          {
            assertion = !(profile.settings ? _config_version);
            message = "${label}: _config_version is set from the installed package; do not declare it.";
          }
          {
            assertion = lib.all (path:
              path != "" && lib.all (part: !(builtins.elem part [ "" "." ".." ]))
                (lib.splitString "/" path)
            ) seedPaths;
            message = "${label}: seedFiles paths must be normalized relative file paths without empty, . or .. components.";
          }
          {
            assertion = lib.all (seed: !(lib.any (pathsOverlap seed) ownedPaths)) seedPaths;
            message = "${label}: seedFiles must not overlap Nix-owned files, cron/jobs.json or the default home's profiles subtree.";
          }
          {
            assertion = lib.all (seed:
              !(lib.any (other: seed != other && pathsOverlap seed other) seedPaths)
            ) seedPaths;
            message = "${label}: seedFiles paths must not nest beneath another seeded file.";
          }
        ]
    ) enabledProfiles);

    home.packages = [ cfg.package ] ++ lib.concatMap (profile: profile.extraPackages) (lib.attrValues enabledProfiles);

    home.file = lib.mapAttrs' (name: _:
      lib.nameValuePair ".local/bin/${name}" {
        executable = true;
        # Hermes writes its own launcher at this path; take it over.
        force = true;
        text = ''
          #!/bin/sh
          exec ${cfg.package}/bin/hermes -p ${lib.escapeShellArg name} "$@"
        '';
      }) (lib.filterAttrs (name: profile: profile.alias && name != "default") enabledProfiles);

    home.activation.hermesProfiles = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] (
      lib.concatStringsSep "\n" (lib.mapAttrsToList profileActivation enabledProfiles)
    );

    # `hermes gateway install` wrote regular unit files (and `systemctl enable`
    # wants-links) at the paths Home Manager now owns; move them aside once so
    # link generation can proceed. Store-backed links are already ours.
    home.activation.hermesRetireGeneratedUnits = lib.mkIf (isLinux && gatewayProfiles != { }) (
      lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        backup="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/pre-nix-units"
        for unit in ${managedUnitFiles}; do
          if [ -f "$unit" ] && [ ! -L "$unit" ]; then
            run mkdir -p "$backup"
            run mv "$unit" "$backup/$(basename "$unit").$(date +%Y%m%d%H%M%S)"
          fi
          for wants in "$(dirname "$unit")"/*.wants/"$(basename "$unit")"; do
            if [ -L "$wants" ] && [ "$(readlink "$wants" | cut -c1-11)" != /nix/store/ ]; then
              run rm "$wants"
            fi
          done
        done
      ''
    );

    systemd.user.services = lib.mkIf isLinux systemdUnits;
    launchd.agents = lib.mkIf isDarwin launchdAgents;
  };
}
