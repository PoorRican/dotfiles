# Centralized Agent Skills distribution for coding agents.
#
# Canonical source layout:
#   configs/agent-skills/default/skills/<category>/<skill>/SKILL.md
#   configs/agent-skills/<host>/skills/<category>/<skill>/SKILL.md
# Distribution policy:
#   configs/agent-skills/collections.nix
#
# Nix builds a flat union directory for each coding agent. Home Manager links
# the top-level members of that view into mutable agent roots, leaving room for
# agent-owned/system entries with other names (for example Codex's .system).
#
# Hermes profiles select from the same catalog roots through hermes.nix; this
# module only publishes the roots (`programs.agent-skills.catalogRoots`).
{ config, lib, pkgs, dotfiles, ... }:
let
  cfg = config.programs.agent-skills;
  skillsLib = import ../lib/agent-skills.nix { inherit lib pkgs; };
  sourceRoot = dotfiles + "/configs/agent-skills";
  collections = import (sourceRoot + "/collections.nix");
  hostCollections = lib.attrByPath [ "hosts" cfg.host ] { coding = [ ]; } collections;
  label = if cfg.host == "" then "default" else cfg.host;

  catalog = skillsLib.mkCatalog cfg.catalogRoots;
  codingNames = lib.unique (collections.coding ++ hostCollections.coding);
  codingSkills = catalog.select codingNames;

  codingView = skillsLib.mkFlatView { name = "coding-${label}"; skills = codingSkills; };

  mkAgentFiles = target:
    lib.listToAttrs (map (skill:
      lib.nameValuePair "${target}/${skill.name}" {
        source = codingView + "/${skill.name}";
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

    catalogRoots = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = ''
        Categorized skill roots that make up the catalog. Defaults to the host
        overlay (when set) followed by the portable default tree. Other modules
        may append private roots; names must stay unique across all roots.
      '';
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

  config = lib.mkMerge [
    {
      programs.agent-skills.catalogRoots =
        lib.optional (cfg.host != "") (sourceRoot + "/${cfg.host}/skills")
        ++ [ (sourceRoot + "/default/skills") ];
    }

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = builtins.pathExists (sourceRoot + "/default/skills");
          message = "Central agent skill root is missing: configs/agent-skills/default/skills";
        }
        (skillsLib.selectionAssertion {
          inherit catalog;
          names = codingNames;
          label = "programs.agent-skills coding collection";
        })
      ] ++ skillsLib.catalogAssertions {
        inherit catalog;
        label = "programs.agent-skills";
      };

      home.file = lib.mkMerge [
        (lib.mkIf cfg.agents.claude (mkAgentFiles ".claude/skills"))
        (lib.mkIf cfg.agents.codex (mkAgentFiles ".codex/skills"))
        (lib.mkIf cfg.agents.pi (mkAgentFiles ".pi/agent/skills"))
        (lib.mkIf cfg.agents.omp (mkAgentFiles ".omp/agent/skills"))
        (lib.mkIf cfg.agents.opencode (mkAgentFiles ".config/opencode/skills"))
      ];

      home.activation.prepareAgentSkillRoots = lib.hm.dag.entryBetween
        [ "linkGeneration" ]
        [ "writeBoundary" ]
        ''
        legacy_root="''${XDG_STATE_HOME:-$HOME/.local/state}/agent-skills/pre-centralization"
        for relative in \
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
    })
  ];
}
