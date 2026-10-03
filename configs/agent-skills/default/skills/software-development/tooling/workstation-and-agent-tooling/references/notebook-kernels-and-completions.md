# Notebook kernels and completions

Scope: Prompt protocols for local FIM completion and the limits of passive notebook-process monitoring.

## FIM prompt protocols

- Mellum2 expects unpiped FIM markers; its working prompt template maps marimo's piped markers to the unpiped forms and renders exactly prefix + suffix + middle, without chat framing. A successful HTTP response does not show that the model received this prompt. (src: marimo-lmstudio-fim; 2026-07-21)
- Native Qwen Chat-FIM recognizes marimo's piped markers; applying the Mellum2 unpiped-marker remapping breaks the intended prompt. (src: marimo-lmstudio-fim; 2026-07-21)
- OpenAI-compatible configuration rejects empty or whitespace API keys; a non-whitespace placeholder can satisfy config validation but is not authentication. (src: marimo-lmstudio-fim; 2026-07-21)
- For a real completion, the rendered model input is the evidence for correct prefix/suffix context and model-family formatting; API success alone cannot establish either. (src: marimo-lmstudio-fim; 2026-07-21)

## Shared kernel monitoring

- A separate system process can read `/proc` CPU ticks, RSS, and system headroom without importing into or executing code inside a shared notebook kernel; this keeps observation outside the workload being monitored. (src: safe-jupyter-kernel-resource-monitor; 2026-07-30)
- CPU idleness or disappearance of an `ipykernel_launcher` process does not establish that a notebook cell succeeded; without independent output evidence it supports only an idle or process-exited interpretation. (src: safe-jupyter-kernel-resource-monitor; 2026-07-30)
- Resource telemetry does not establish that interruption or restart is safe; kernel control remains a user decision because intervention can discard in-progress work. (src: safe-jupyter-kernel-resource-monitor; 2026-07-30)
