{ lib, ... }:
{
  model = {
    default = "gpt-5.4";
    provider = "openai-codex";
    base_url = "https://chatgpt.com/backend-api/codex";
  };
  fallback_providers = [ ];
  credential_pool_strategies = {};
  toolsets = [ "all" ];
  agent = {
    max_turns = 75;
    tool_use_enforcement = "auto";
    verbose = false;
    reasoning_effort = "medium";
    personalities = {
      helpful = "You are a helpful, friendly AI assistant.";
      concise = "You are a concise assistant. Keep responses brief and to the point.";
      technical = "You are a technical expert. Provide detailed, accurate technical information.";
      creative = "You are a creative assistant. Think outside the box and offer innovative solutions.";
      teacher = "You are a patient teacher. Explain concepts clearly with examples.";
    };
    system_prompt = "You are a highly organized hacker engineer extraoridaire. You think outside of the box and offer creative solutions and validate your ideas before surfacing them.";
  };
  terminal = {
    backend = "local";
    cwd = ".";
    timeout = 180;
    env_passthrough = [ ];
    docker_image = "nikolaik/python-nodejs:python3.11-nodejs20";
    docker_forward_env = [ ];
    singularity_image = "docker://nikolaik/python-nodejs:python3.11-nodejs20";
    modal_image = "nikolaik/python-nodejs:python3.11-nodejs20";
    daytona_image = "nikolaik/python-nodejs:python3.11-nodejs20";
    container_cpu = 1;
    container_memory = 5120;
    container_disk = 51200;
    container_persistent = true;
    docker_volumes = [ ];
    docker_mount_cwd_to_workspace = false;
    persistent_shell = true;
    lifetime_seconds = 300;
  };
  browser = {
    inactivity_timeout = 120;
    command_timeout = 30;
    record_sessions = false;
    allow_private_urls = false;
  };
  checkpoints = {
    enabled = false;
    max_snapshots = 50;
  };
  file_read_max_chars = 100000;
  compression = {
    enabled = true;
    threshold = 0.85;
    target_ratio = 0.2;
    protect_last_n = 20;
    summary_model = "google/gemini-3-flash-preview";
    summary_provider = "auto";
    summary_base_url = null;
  };
  smart_model_routing = {
    enabled = false;
    max_simple_chars = 160;
    max_simple_words = 28;
    cheap_model = {};
  };
  auxiliary = {
    vision = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 30;
      download_timeout = 30;
    };
    web_extract = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 30;
    };
    compression = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 120;
    };
    session_search = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 30;
    };
    skills_hub = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 30;
    };
    approval = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 30;
    };
    mcp = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 30;
    };
    flush_memories = {
      provider = "auto";
      model = "";
      base_url = "";
      api_key = "";
      timeout = 30;
    };
  };
  display = {
    compact = false;
    personality = "kawaii";
    resume_display = "full";
    busy_input_mode = "interrupt";
    bell_on_complete = true;
    show_reasoning = true;
    streaming = true;
    show_cost = false;
    skin = "default";
    tool_progress_command = false;
    tool_preview_length = 0;
    tool_progress = "all";
    background_process_notifications = "all";
  };
  privacy = {
    redact_pii = false;
  };
  tts = {
    provider = "edge";
    edge = {
      voice = "en-US-AriaNeural";
    };
    elevenlabs = {
      voice_id = "pNInz6obpgDQGcFmaJgB";
      model_id = "eleven_multilingual_v2";
    };
    openai = {
      model = "gpt-4o-mini-tts";
      voice = "alloy";
    };
    neutts = {
      ref_audio = "";
      ref_text = "";
      model = "neuphonic/neutts-air-q4-gguf";
      device = "cpu";
    };
  };
  stt = {
    enabled = true;
    provider = "local";
    local = {
      model = "base";
    };
    openai = {
      model = "whisper-1";
    };
    model = "whisper-1";
  };
  voice = {
    record_key = "ctrl+b";
    max_recording_seconds = 120;
    auto_tts = false;
    silence_threshold = 200;
    silence_duration = 3.0;
  };
  human_delay = {
    mode = "off";
    min_ms = 800;
    max_ms = 2500;
  };
  memory = {
    memory_enabled = true;
    user_profile_enabled = true;
    memory_char_limit = 2200;
    user_char_limit = 1375;
    nudge_interval = 10;
    flush_min_turns = 6;
  };
  delegation = {
    model = "";
    provider = "";
    base_url = "";
    api_key = "";
    max_iterations = 50;
    default_toolsets = [ "terminal" "file" "web" ];
  };
  prefill_messages_file = "";
  skills = {
    external_dirs = [ ];
    creation_nudge_interval = 15;
    disabled = [ "dogfood" "faiss" "find-nearby" "google-workspace" "llava" "minecraft-modpack-server" "pinecone" "pokemon-player" "powerpoint" ];
  };
  honcho = {};
  timezone = "";
  discord = {
    require_mention = true;
    free_response_channels = "";
    auto_thread = true;
    reactions = true;
  };
  whatsapp = {};
  approvals = {
    mode = "manual";
    timeout = 60;
  };
  command_allowlist = [ ];
  quick_commands = {};
  personalities = {};
  security = {
    redact_secrets = true;
    tirith_enabled = true;
    tirith_path = "tirith";
    tirith_timeout = 5;
    tirith_fail_open = true;
    website_blocklist = {
      enabled = false;
      domains = [ ];
      shared_files = [ ];
    };
  };
  cron = {
    wrap_response = true;
  };
  session_reset = {
    mode = "both";
    idle_minutes = 1440;
    at_hour = 4;
  };
  platform_toolsets = {
    cli = [ "browser" "clarify" "code_execution" "cronjob" "delegation" "file" "image_gen" "memory" "session_search" "skills" "terminal" "todo" "tts" "vision" "web" ];
    discord = [ "hermes-discord" ];
    homeassistant = [ "hermes-homeassistant" ];
  };
  code_execution = {
    timeout = 300;
    max_tool_calls = 50;
  };
  bell = true;
  reasoning = "all";
}
