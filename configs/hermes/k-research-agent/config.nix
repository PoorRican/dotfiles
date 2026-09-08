# k-research-agent policy: the public half of the profile (model, tools,
# limits). Persona, private skills and scheduled work come from the private
# agent-profiles input composed in nix/hosts/cbox.nix.
#
# Only deviations from the Hermes defaults belong here; the file is rendered
# into config.yaml and replaced on every activation.
{ ... }:
let
  # Research work drives a desktop and posts to messaging, which the default
  # profile's toolset deliberately leaves out.
  cliToolsets = [
    "browser"
    "clarify"
    "code_execution"
    "computer_use"
    "cronjob"
    "delegation"
    "file"
    "image_gen"
    "memory"
    "messaging"
    "session_search"
    "skills"
    "terminal"
    "todo"
    "tts"
    "vision"
    "web"
  ];
  discordToolsets = [
    "browser"
    "clarify"
    "code_execution"
    "context_engine"
    "cronjob"
    "delegation"
    "discord"
    "file"
    "memory"
    "messaging"
    "session_search"
    "skills"
    "terminal"
    "todo"
    "vision"
    "web"
  ];
in {
  model = {
    default = "gpt-6-astra";
    provider = "openai-codex";
    base_url = "https://chatgpt.com/backend-api/codex";
  };
  custom_providers = [
    {
      name = "spark (vllm)";
      base_url = "http://spark-a0c2.home.local:8000/v1";
      model = "Tess-4-27B";
      models."Tess-4-27B".context_length = 80000;
    }
  ];

  toolsets = cliToolsets;
  platform_toolsets = {
    cli = cliToolsets;
    discord = discordToolsets;
  };

  agent = {
    max_turns = 150;
    # Long research turns: give the gateway time to drain before a restart.
    restart_drain_timeout = 180;
    clarify_timeout = 600;
  };

  web = {
    backend = "ddgs";
    use_gateway = false;
  };
  browser = {
    cloud_provider = "local";
    use_gateway = false;
  };
  auxiliary.web_extract.timeout = 360;
  compression.hygiene_hard_message_limit = 400;

  display = {
    personality = "kawaii";
    show_reasoning = false;
    tool_progress = "new";
  };
  stt.provider = "local";

  delegation = {
    max_iterations = 50;
    child_timeout_seconds = 600;
    max_concurrent_children = 3;
  };

  approvals = {
    mode = "manual";
    timeout = 60;
  };

  # Research sessions span days; never reset them on a schedule.
  session_reset.mode = "none";
}
