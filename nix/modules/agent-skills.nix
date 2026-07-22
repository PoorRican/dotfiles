# Centralized Agent Skills distribution.
#
# Canonical source layout:
#   configs/agent-skills/default/skills/<category>/<skill>/SKILL.md
#   configs/agent-skills/<host>/skills/<category>/<skill>/SKILL.md
# Distribution policy:
#   configs/agent-skills/collections.nix
#
# Hermes receives the categorized trees as an immutable external directory.
# Nix builds a flat union directory for each coding agent. Home Manager links the
# top-level members of those views into mutable agent roots, leaving room for
# agent-owned/system entries with other names (for example Codex's .system).
{ config, lib, pkgs, dotfiles, ... }:
let
  cfg = config.programs.agent-skills;
  sourceRoot = dotfiles + "/configs/agent-skills";
  defaultRoot = sourceRoot + "/default/skills";
  hostRoot = sourceRoot + "/${cfg.host}/skills";
  collections = import (sourceRoot + "/collections.nix");
  hostCollections = lib.attrByPath [ "hosts" cfg.host ] {
    coding = [ ];
    hermes = [ ];
  } collections;

  scanRoot = root:
    let
      walk = relative:
        let
          directory = if relative == "" then root else root + "/${relative}";
          entries = builtins.readDir directory;
        in
          lib.concatLists (lib.mapAttrsToList (name: type:
            let
              path = directory + "/${name}";
              childRelative = if relative == "" then name else "${relative}/${name}";
              isDirectory = builtins.elem type [ "directory" "symlink" ];
            in
              if isDirectory && builtins.pathExists (path + "/SKILL.md") then [ {
                inherit name path;
                category = relative;
              } ]
              else if type == "directory" then walk childRelative
              else [ ]
          ) entries);
    in
      walk "";

  roots =
    lib.optional (cfg.host != "" && builtins.pathExists hostRoot) hostRoot
    ++ [ defaultRoot ];
  catalogSkills = lib.concatMap scanRoot roots;
  skillsByName = lib.groupBy (skill: skill.name) catalogSkills;
  duplicateNames = lib.attrNames (lib.filterAttrs (_: matches: builtins.length matches > 1) skillsByName);
  uncategorizedSkills = map (skill: skill.name) (lib.filter (skill: skill.category == "") catalogSkills);
  invalidPathSkills = map (skill: skill.name) (lib.filter (skill:
    let
      parts = lib.splitString "/" skill.category ++ [ skill.name ];
    in
      lib.any (part: lib.hasPrefix "." part || lib.hasSuffix ".bak" part) parts
  ) catalogSkills);
  invalidNameSkills = map (skill: skill.name) (lib.filter
    (skill: builtins.match "[A-Za-z0-9][A-Za-z0-9._-]*" skill.name == null)
    catalogSkills);

  codingNames = lib.unique (collections.coding ++ hostCollections.coding);
  hermesNames = lib.unique (codingNames ++ collections.hermes ++ hostCollections.hermes);
  missingCodingNames = lib.filter (name: !(builtins.hasAttr name skillsByName)) codingNames;
  missingHermesNames = lib.filter (name: !(builtins.hasAttr name skillsByName)) hermesNames;
  selectSkills = names: map
    (name: builtins.head skillsByName.${name})
    (lib.filter (name: builtins.hasAttr name skillsByName) names);
  codingSkills = selectSkills codingNames;
  hermesSkills = selectSkills hermesNames;

  categorizedView = pkgs.runCommand "agent-skills-categorized-${if cfg.host == "" then "default" else cfg.host}" { } ''
    mkdir -p "$out"
    ${lib.concatMapStringsSep "\n" (skill: ''
      mkdir -p "$out/${skill.category}"
      ln -s ${skill.path} "$out/${skill.category}/${skill.name}"
    '') hermesSkills}
  '';

  mkAgentView = agent:
    pkgs.linkFarm "${agent}-skills-${if cfg.host == "" then "default" else cfg.host}"
      (map (skill: {
        name = skill.name;
        path = skill.path;
      }) codingSkills);

  mkAgentFiles = agent: target:
    let
      view = mkAgentView agent;
    in
      lib.listToAttrs (map (skill:
        lib.nameValuePair "${target}/${skill.name}" {
          source = view + "/${skill.name}";
          force = cfg.force;
        }
      ) codingSkills);

  managedSkillNames = lib.concatMapStringsSep " "
    (skill: lib.escapeShellArg skill.name)
    codingSkills;
in {
  options.programs.agent-skills = {
    enable = lib.mkEnableOption "centralized cross-agent skill distribution";

    host = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional host overlay under configs/agent-skills/<host>/skills.";
    };

    force = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Replace same-name legacy skill entries with the centralized copy.";
    };

    agents = {
      claude = lib.mkEnableOption "Claude Code skill distribution" // { default = true; };
      codex = lib.mkEnableOption "Codex skill distribution" // { default = true; };
      pi = lib.mkEnableOption "Pi skill distribution" // { default = true; };
      omp = lib.mkEnableOption "OMP skill distribution" // { default = true; };
      opencode = lib.mkEnableOption "OpenCode skill distribution" // { default = true; };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.pathExists defaultRoot;
        message = "Central agent skill root is missing: configs/agent-skills/default/skills";
      }
      {
        assertion = duplicateNames == [ ];
        message = "Central agent skills expose duplicate names: ${lib.concatStringsSep ", " duplicateNames}";
      }
      {
        assertion = uncategorizedSkills == [ ];
        message = "Central agent skills must be below a category: ${lib.concatStringsSep ", " uncategorizedSkills}";
      }
      {
        assertion = invalidPathSkills == [ ];
        message = "Central agent skills contain hidden or backup path components: ${lib.concatStringsSep ", " invalidPathSkills}";
      }
      {
        assertion = invalidNameSkills == [ ];
        message = "Central agent skills contain invalid directory names: ${lib.concatStringsSep ", " invalidNameSkills}";
      }
      {
        assertion = missingCodingNames == [ ];
        message = "Coding skill collection references missing names: ${lib.concatStringsSep ", " missingCodingNames}";
      }
      {
        assertion = missingHermesNames == [ ];
        message = "Hermes skill collection references missing names: ${lib.concatStringsSep ", " missingHermesNames}";
      }
    ];

    home.file = lib.mkMerge [
      (lib.mkIf cfg.agents.claude (mkAgentFiles "claude" ".claude/skills"))
      (lib.mkIf cfg.agents.codex (mkAgentFiles "codex" ".codex/skills"))
      (lib.mkIf cfg.agents.pi (mkAgentFiles "pi" ".pi/agent/skills"))
      (lib.mkIf cfg.agents.omp (mkAgentFiles "omp" ".omp/agent/skills"))
      (lib.mkIf cfg.agents.opencode (mkAgentFiles "opencode" ".config/opencode/skills"))
      {
        ".hermes/.no-bundled-skills".text = ''
          This profile uses the centralized agent skill library and has opted out of bundled skill seeding.
          Remove this file only if bundled skill synchronization is intentionally restored.
        '';
      }
    ];

    programs.hermes.settings.skills.external_dirs = [ (toString categorizedView) ];

    home.activation.prepareAgentSkillRoots = lib.hm.dag.entryBetween
      [ "linkGeneration" ]
      [ "writeBoundary" ]
      ''
      for relative in \
        ".hermes/skills" \
        ".claude/skills" \
        ".codex/skills" \
        ".pi/agent/skills" \
        ".omp/agent/skills" \
        ".config/opencode/skills"
      do
        root="$HOME/$relative"
        if [ -L "$root" ]; then
          rm "$root"
        fi
        mkdir -p "$root"
      done

      legacy_root="''${XDG_STATE_HOME:-$HOME/.local/state}/agent-skills/pre-centralization"
      for relative in \
        ".claude/skills" \
        ".codex/skills" \
        ".pi/agent/skills" \
        ".omp/agent/skills" \
        ".config/opencode/skills"
      do
        root="$HOME/$relative"
        for name in ${managedSkillNames}; do
          target="$root/$name"
          backup="$legacy_root/$relative/$name"
          if [ -L "$target" ]; then
            rm "$target"
          elif [ -e "$target" ]; then
            if [ -e "$backup" ] || [ -L "$backup" ]; then
              echo "Refusing to replace $target: migration backup already exists at $backup" >&2
              exit 1
            fi
            mkdir -p "$(dirname "$backup")"
            mv "$target" "$backup"
          fi
        done
      done
    '';
  };
}
