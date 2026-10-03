# Explicit distribution collections for the centralized skill catalog.
#
# `coding` is the complete set shared by coding agents.
# `hermes` is additive: the default Hermes profile receives coding ++ hermes.
# Named Hermes profiles select their own names (programs.hermes.profiles.<name>.skills.names).
# Host collections are additive to their corresponding global collection.
{
  coding = [
    "agent-orchestration"
    "analysis-judgement"
    "code-liveness-and-refactoring"
    "data-inspection"
    "debugging"
    "documentation-curation"
    "git-and-github"
    "marimo-pair"
    "performance-and-throughput"
    "prose-writing-style"
    "rust-engineering"
    "using-nautilus-trader"
    "verification-and-evidence"
    "workstation-and-agent-tooling"
  ];

  hermes = [
    "architecture-diagram"
    "arxiv"
    "axolotl"
    "blogwatcher"
    "computer-use"
    "domain-intel"
    "dspy"
    "duckduckgo-search"
    "evaluating-llms-harness"
    "experiment-log-interview"
    "experiment-log-structure"
    "fine-tuning-with-trl"
    "gguf-quantization"
    "huggingface-hub"
    "llama-cpp"
    "llm-wiki"
    "maps"
    "ml-paper-writing"
    "modal-serverless-gpu"
    "native-mcp"
    "obsidian"
    "qdrant-vector-search"
    "research-paper-writing"
    "research-proposal-interview"
    "research-proposal-structure"
    "serving-llms-vllm"
    "spotify"
    "teams-meeting-pipeline"
    "unsloth"
    "using-proton-pass-cli"
    "weights-and-biases"
  ];

  hosts = {
    cbox = {
      coding = [ ];
      hermes = [
        "media-transfer-to-te-amo"
        "te-amo-tv-show-layout"
      ];
    };

    dgx = {
      coding = [ ];
      hermes = [ ];
    };

    emc = {
      coding = [ ];
      hermes = [ ];
    };

    mbp = {
      coding = [ ];
      hermes = [ "macos-computer-use" ];
    };
  };
}
