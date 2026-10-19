# cbox server
{ config, lib, pkgs, dotfiles, inputs, ... }:
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

  # Keep LM Studio available alongside the portable Codex default.
  programs.hermes.profiles.default.settings = {
    # Preserve this host's approved live behavior on declarative activation.
    gateway.multiplex_profiles = true;
    approvals.destructive_slash_confirm = false;
    display.busy_input_mode = "interrupt";
    # The default profile's webhook listener owns port 8644 and forwards /p/<profile>/ routes.
    platforms.webhook = {
      enabled = true;
      extra.port = 8644;
    };

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
