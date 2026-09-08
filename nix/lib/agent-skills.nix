# Skill catalog primitives shared by agent-skills.nix (coding agents) and
# hermes.nix (per-profile Hermes skill views).
#
# A catalog root is a categorized tree:
#   <root>/<category>[/<subcategory>]/<skill>/SKILL.md
# Every root contributes complete bundles; the directory basename is the skill
# name and must be unique across all roots that feed one view.
{ lib, pkgs }:
let
  # Every skill bundle below one root, with its category path.
  scanRoot = root:
    let
      walk = relative:
        let
          directory = if relative == "" then root else root + "/${relative}";
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
          ) (builtins.readDir directory));
    in
      walk "";

  # Assemble one catalog from several roots. Missing roots are skipped so a
  # host overlay directory is optional.
  mkCatalog = roots:
    let
      skills = lib.concatMap scanRoot (lib.filter builtins.pathExists roots);
      byName = lib.groupBy (skill: skill.name) skills;
    in {
      inherit roots skills byName;
      # Names that resolve to a single bundle.
      names = lib.attrNames byName;
      select = names: map
        (name: builtins.head byName.${name})
        (lib.filter (name: builtins.hasAttr name byName) names);
      missing = names: lib.filter (name: !(builtins.hasAttr name byName)) names;
    };

  # Structural assertions for one catalog. `label` names the consumer so a
  # failure points at the right option.
  catalogAssertions = { catalog, label }:
    let
      duplicateNames = lib.attrNames (lib.filterAttrs (_: matches: builtins.length matches > 1) catalog.byName);
      uncategorized = map (skill: skill.name) (lib.filter (skill: skill.category == "") catalog.skills);
      hiddenOrBackup = map (skill: skill.name) (lib.filter (skill:
        lib.any (part: lib.hasPrefix "." part || lib.hasSuffix ".bak" part)
          (lib.splitString "/" skill.category ++ [ skill.name ])
      ) catalog.skills);
      invalidNames = map (skill: skill.name) (lib.filter
        (skill: builtins.match "[A-Za-z0-9][A-Za-z0-9._-]*" skill.name == null)
        catalog.skills);
      join = lib.concatStringsSep ", ";
    in [
      {
        assertion = duplicateNames == [ ];
        message = "${label}: skill catalog exposes duplicate names: ${join duplicateNames}";
      }
      {
        assertion = uncategorized == [ ];
        message = "${label}: skills must sit below a category: ${join uncategorized}";
      }
      {
        assertion = hiddenOrBackup == [ ];
        message = "${label}: skill paths contain hidden or backup components: ${join hiddenOrBackup}";
      }
      {
        assertion = invalidNames == [ ];
        message = "${label}: skill directory names are invalid: ${join invalidNames}";
      }
    ];

  # Assert that every selected name exists in the catalog.
  selectionAssertion = { catalog, names, label }:
    let
      missing = catalog.missing names;
    in {
      assertion = missing == [ ];
      message = "${label}: selection references unknown skills: ${lib.concatStringsSep ", " missing}";
    };

  # Immutable categorized view (Hermes `skills.external_dirs` shape).
  mkCategorizedView = { name, skills }:
    pkgs.runCommand "agent-skills-categorized-${name}" { } ''
      mkdir -p "$out"
      ${lib.concatMapStringsSep "\n" (skill: ''
        mkdir -p "$out/${skill.category}"
        ln -s ${skill.path} "$out/${skill.category}/${skill.name}"
      '') skills}
    '';

  # Immutable flat view (coding-agent `<root>/<skill>` shape).
  mkFlatView = { name, skills }:
    pkgs.linkFarm "agent-skills-flat-${name}" (map (skill: {
      inherit (skill) name path;
    }) skills);
in {
  inherit
    scanRoot
    mkCatalog
    catalogAssertions
    selectionAssertion
    mkCategorizedView
    mkFlatView
    ;
}
