{ pkgs, lib, inputs, dotfiles, extras ? [ "all" ], ... }:
let
  hermesSrc = inputs.hermes-agent.outPath;
  flakeLock = builtins.fromJSON (builtins.readFile (dotfiles + "/flake.lock"));

  getLockedFlake = nodeName:
    let
      node = flakeLock.nodes.${nodeName}.locked;
    in
    builtins.getFlake "github:${node.owner}/${node.repo}/${node.rev}";

  pyprojectBuildSystems = getLockedFlake "pyproject-build-systems";
  pyprojectNix = getLockedFlake "pyproject-nix_2";
  uv2nix = getLockedFlake "uv2nix_2";

  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = hermesSrc; };
  hacks = pkgs.callPackage pyprojectNix.build.hacks { };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  isAarch64Darwin = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";

  mkPrebuiltPassthru = dependencies: {
    inherit dependencies;
    optional-dependencies = { };
    dependency-groups = { };
  };

  mkPrebuiltOverride = final: from: dependencies:
    hacks.nixpkgsPrebuilt {
      inherit from;
      prev = {
        nativeBuildInputs = [ final.pyprojectHook ];
        passthru = mkPrebuiltPassthru dependencies;
      };
    };

  pythonPackageOverrides = final: prev:
    let
      addBuildSystems = package: systems:
        package.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ final.resolveBuildSystem systems;
        });

      atroposlibFixed = addBuildSystems prev.atroposlib {
        hatchling = [ ];
      };

      tinkerFixed = prev.tinker.overrideAttrs (old: {
        nativeBuildInputs =
          (old.nativeBuildInputs or [ ])
          ++ final.resolveBuildSystem {
            hatchling = [ ];
          }
          ++ [ final."hatch-fancy-pypi-readme" ];
      });
    in
    (if isAarch64Darwin then {
      numpy = mkPrebuiltOverride final pkgs.python311.pkgs.numpy { };

      av = mkPrebuiltOverride final pkgs.python311.pkgs.av { };

      humanfriendly = mkPrebuiltOverride final pkgs.python311.pkgs.humanfriendly { };

      coloredlogs = mkPrebuiltOverride final pkgs.python311.pkgs.coloredlogs {
        humanfriendly = [ ];
      };

      onnxruntime = mkPrebuiltOverride final pkgs.python311.pkgs.onnxruntime {
        coloredlogs = [ ];
        numpy = [ ];
        packaging = [ ];
      };

      ctranslate2 = mkPrebuiltOverride final pkgs.python311.pkgs.ctranslate2 {
        numpy = [ ];
        pyyaml = [ ];
      };

      faster-whisper = mkPrebuiltOverride final pkgs.python311.pkgs.faster-whisper {
        av = [ ];
        ctranslate2 = [ ];
        huggingface-hub = [ ];
        onnxruntime = [ ];
        tokenizers = [ ];
        tqdm = [ ];
      };
    } else { })
    // {
      atroposlib = atroposlibFixed;
      tinker = tinkerFixed;
    };

  pythonSet =
    (pkgs.callPackage pyprojectNix.build.packages {
      python = pkgs.python311;
    }).overrideScope
      (lib.composeManyExtensions [
        pyprojectBuildSystems.overlays.default
        overlay
        pythonPackageOverrides
      ]);

  hermesVenv = pythonSet.mkVirtualEnv "hermes-agent-env-custom" {
    hermes-agent = extras;
  };

  hermesTuiSrc = hermesSrc + "/ui-tui";
  hermesTuiPackageJson = builtins.fromJSON (builtins.readFile (hermesTuiSrc + "/package.json"));
  hermesTui = pkgs.buildNpmPackage {
      pname = "hermes-tui";
      src = hermesTuiSrc;
      version = hermesTuiPackageJson.version;
      npmDepsHash = "sha256-zsUPmbC6oMUO10EhS3ptvDjwlfpCSEmrkjyeORw7fac=";

      doCheck = false;

      postPatch = ''
        sed -i -z 's/\n$//' package-lock.json
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/hermes-tui
        cp -r dist $out/lib/hermes-tui/dist
        cp -r node_modules $out/lib/hermes-tui/node_modules
        rm -f $out/lib/hermes-tui/node_modules/@hermes/ink
        cp -r packages/hermes-ink $out/lib/hermes-tui/node_modules/@hermes/ink
        cp package.json $out/lib/hermes-tui/

        runHook postInstall
      '';
    };

  bundledSkills = pkgs.lib.cleanSourceWith {
    src = hermesSrc + "/skills";
    filter = path: _type: !(pkgs.lib.hasInfix "/index-cache/" path);
  };

  runtimeDeps = with pkgs; [
    nodejs_22
    ripgrep
    git
    openssh
    ffmpeg
    tirith
  ];

  runtimePath = pkgs.lib.makeBinPath runtimeDeps;
  pyproject = builtins.fromTOML (builtins.readFile (hermesSrc + "/pyproject.toml"));
in
pkgs.stdenv.mkDerivation {
  pname = "hermes-agent";
  version = pyproject.project.version;

  dontUnpack = true;
  dontBuild = true;
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/hermes-agent $out/bin
    cp -r ${bundledSkills} $out/share/hermes-agent/skills

    mkdir -p $out/ui-tui
    cp -r ${hermesTui}/lib/hermes-tui/* $out/ui-tui/

    ${pkgs.lib.concatMapStringsSep "\n"
      (name: ''
        makeWrapper ${hermesVenv}/bin/${name} $out/bin/${name} \
          --suffix PATH : "${runtimePath}" \
          --set HERMES_BUNDLED_SKILLS $out/share/hermes-agent/skills \
          --set HERMES_TUI_DIR $out/ui-tui \
          --set HERMES_PYTHON ${hermesVenv}/bin/python3
      '')
      [
        "hermes"
        "hermes-agent"
        "hermes-acp"
      ]
    }

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "AI agent with advanced tool-calling capabilities";
    homepage = "https://github.com/NousResearch/hermes-agent";
    mainProgram = "hermes";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
