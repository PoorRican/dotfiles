---
name: workstation-and-agent-tooling
description: "Use for personal workstation and agent-runtime tooling: Hermes profiles and Nix/Home Manager daemon configuration, native desktop popups, Waybar and Neovim runtime issues, interactive TUI and agent-harness testing, notebook kernels and FIM completions, skill packaging, and secure remote secret installation."
---

# Workstation and agent tooling

Workstation failures often come from runtime ownership or version-specific behavior, not the spelling of a config: a deployed file, active service, attached highlighter, or successful API response can still mask a consumer that did not apply it. These references capture the less-visible distinctions behind those symptoms and label suite- or version-specific behavior rather than presenting it as universal. Open the focused reference for the component or boundary you are diagnosing.

| When you are… | Open |
|---|---|
| Testing interactive terminal behavior, editor motions, or a live agent harness | [references/agent-harness-testing.md](references/agent-harness-testing.md) |
| Integrating native popups, diagnosing Waybar modules, Neovim highlighting, or an input daemon | [references/desktop-and-editor-apps.md](references/desktop-and-editor-apps.md) |
| Working with Hermes profile ownership, Nix merges, or daemon configuration | [references/hermes-profiles-and-nix.md](references/hermes-profiles-and-nix.md) |
| Debugging notebook FIM prompts or monitoring a shared notebook kernel | [references/notebook-kernels-and-completions.md](references/notebook-kernels-and-completions.md) |
| Installing or validating a remote credential | [references/secrets-handling.md](references/secrets-handling.md) |
| Packaging a skill or assessing a discovered skill | [references/skill-tooling.md](references/skill-tooling.md) |

Canonical docs: [Hermes profile contract](/home/swe/dotfiles/configs/hermes/README.md) — current profile composition, configuration ownership, and runtime-state boundaries.
