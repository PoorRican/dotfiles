# cbox server
{ config, lib, pkgs, dotfiles, inputs, ... }:
let
  upstreamHermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hindsight = import (dotfiles + "/configs/hermes/k-research-agent/hindsight.nix") {
    inherit pkgs;
    python = upstreamHermes.python;
  };
in
{
  imports = [
    ../profiles/minimal.nix
    ../profiles/shell.nix
    ../profiles/server.nix
    ../profiles/i3-desktop.nix
    ../profiles/hyprland-desktop.nix
    ../profiles/dev-core.nix
    ../profiles/dev-extra.nix
    ../profiles/pkm.nix
    # Keep the suspended cleanup prototype out of activation until independently approved.
    ../modules/btrfs-watch.nix
    # not used at this moment
    #../layers/knowledge-tools.nix
  ];

  # The shared Neovim module manages the full ~/.config/nvim tree and installs
  # the Neovim binary package directly. Keep Home Manager's program module off
  # here so it does not generate ~/.config/nvim/init.lua alongside the symlinked
  # config tree.
  programs.neovim.enable = lib.mkForce false;
  programs.agent-skills.host = "cbox";

  # This host composes the private profile flake; other hosts leave capture
  # provenance unset and do not force this local-only input.
  programs.hermes.capture.sourceRevisions."agent-profiles" = inputs.agent-profiles.rev or null;

  # The default profile serves Discord here; Nix owns hermes-gateway.service.
  programs.hermes.profiles.default.gateway.enable = true;

  # The optional memory plugin augments the same sealed runtime used by CLI
  # and gateways; only k-research-agent receives its code and connection config.
  programs.hermes.package = assert inputs.hermes-agent.rev == hindsight.hermesIdentity.revision;
    (upstreamHermes.override {
    inherit (hindsight.hermesIdentity) version distance;
    extraDependencyGroups = config.programs.hermes.extras;
    extraPythonPackages = hindsight.pythonPackages;
  }).overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      hindsightDependencyNames = map (package: package.pname) hindsight.pythonPackages;
    };
  });

  systemd.user.services.hindsight-tunnel-k-research-agent = hindsight.tunnelService;
  systemd.user.services.hermes-gateway-k-research-agent.Unit = {
    Requires = [ "hindsight-tunnel-k-research-agent.service" ];
    After = [ "hindsight-tunnel-k-research-agent.service" ];
  };

  # k-research-agent: public half (policy, public skills, gateway). The
  # private agent-profiles input composed in flake.nix adds the persona and
  # private skills to this same profile.
  programs.hermes.profiles.k-research-agent = {
    settings = import (dotfiles + "/configs/hermes/k-research-agent/config.nix") { };
    files = hindsight.files;
    skills.names = import (dotfiles + "/configs/hermes/k-research-agent/skills.nix");
    gateway.enable = true;
  };

  # Keep LM Studio available alongside the portable Codex default.
  programs.hermes.profiles.default.settings = {
    custom_providers = [
      {
        name = "lmstudio";
        base_url = "http://localhost:1234/v1";
        model = "google/gemma-4-12b-qat";
      }
			{
				name = "vllm(spark)";
				base_url = "http://spark-a0c2.home.local:8000/v1";
			}
    ];
  };

  home.packages = with pkgs; [
		noto-fonts
		noto-fonts-cjk-sans
		noto-fonts-color-emoji
	];
}
