# Default Hermes profile policy (~/.hermes) for every host that enables
# programs.hermes. Only deviations from the Hermes defaults belong here: the
# file is rendered into config.yaml and replaced on every activation, and the
# renderer rejects keys the installed Hermes release does not know.
#
# Hosts extend or override individual keys through
# programs.hermes.profiles.default.settings (use lib.mkForce for a leaf that
# is already set here). Secrets never belong here; they live in ~/.hermes/.env.
{ ... }:
let
  # The default profile is the general assistant. Privileged profiles
  # (research, sysadmin) are declared in the private flake with their own
  # toolsets; keep this list free of computer_use and messaging.
  cliToolsets = [
    "browser"
    "clarify"
    "code_execution"
    "cronjob"
    "delegation"
    "file"
    "image_gen"
    "memory"
    "session_search"
    "skills"
    "terminal"
    "todo"
    "tts"
    "vision"
    "web"
  ];
in {
  model = {
    default = "gpt-5.5";
    provider = "openai-codex";
    base_url = "https://chatgpt.com/backend-api/codex";
  };

  toolsets = cliToolsets;
  platform_toolsets = {
    cli = cliToolsets;
    discord = [ "hermes-discord" ];
    homeassistant = [ "hermes-homeassistant" ];
  };

  agent = {
    max_turns = 75;
    reasoning_effort = "xhigh";
    system_prompt = "You are a highly organized hacker engineer extraoridaire. You think outside of the box and offer creative solutions and validate your ideas before surfacing them.";
    personalities = {
      helpful = "You are a helpful, friendly AI assistant.";
      concise = "You are a concise assistant. Keep responses brief and to the point.";
      technical = "You are a technical expert. Provide detailed, accurate technical information.";
      creative = "You are a creative assistant. Think outside the box and offer innovative solutions.";
      teacher = "You are a patient teacher. Explain concepts clearly with examples.";
    };
  };

  terminal.lifetime_seconds = 300;

  checkpoints.max_snapshots = 50;

  compression = {
    threshold = 0.85;
    summary_model = "google/gemini-3-flash-preview";
    summary_provider = "auto";
  };

  auxiliary.vision.timeout = 30;

  display = {
    personality = "kawaii";
    bell_on_complete = true;
    streaming = true;
    tool_progress = "all";
    background_process_notifications = "all";
  };

  stt = {
    provider = "local";
    model = "whisper-1";
  };

  memory.flush_min_turns = 6;

  delegation = {
    max_iterations = 50;
    default_toolsets = [ "terminal" "file" "web" ];
  };

  code_execution = {
    timeout = 300;
    max_tool_calls = 50;
  };

  approvals = {
    mode = "manual";
    timeout = 60;
  };

  session_reset = {
    mode = "both";
    idle_minutes = 1440;
    at_hour = 4;
  };

  skills = {
    creation_nudge_interval = 15;
    # Bundled skills seeded into ~/.hermes/skills before the catalog was
    # centralized. Nix no longer seeds bundled skills; this list only hides
    # leftover local copies until `hermes skills opt-out --remove` prunes them.
    disabled = [ "apple" "apple-notes" "apple-reminders" "ascii-art" "ascii-video" "atlas-history" "dogfood" "excalidraw" "faiss" "find-nearby" "findmy" "gif-search" "godmode" "google-workspace" "heartmula" "hermes-agent-setup" "himalaya" "imessage" "inference-sh-cli" "linear" "llava" "minecraft-modpack-server" "nano-pdf" "notion" "ocr-and-documents" "openhue" "pinecone" "polymarket" "pokemon-player" "powerpoint" "skill-creator" "songsee" "songwriting-and-ai-music" "xitter" "youtube-content" ];
  };
}
