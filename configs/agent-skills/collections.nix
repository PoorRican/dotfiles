# Explicit distribution collections for the centralized skill catalog.
#
# `coding` is the complete set shared by coding agents.
# `hermes` is additive: Hermes receives coding ++ hermes.
# Host collections are additive to their corresponding global collection.
{
  coding = [
		"brainstorm"
    "brainstorming"
    "code-review"  # provenance
    "conventional-commits"
    "github-code-review"
    "github-issues"
    "github-pr-workflow"
    "linux-system-debugging"
    "local-columnar-data-inspection"
    "marimo-pair"
    "package-skill"
    "python-debugpy"
    "requesting-code-review"
		"prose-writing-style"
    "simplify-code"
    "spike"
    "stacked-issues"
    "stacked-prs"
    "subagent-driven-development"
    "systematic-debugging"
    "test-driven-development"
    "using-nautilus-trader"
    "writing-plans"
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
