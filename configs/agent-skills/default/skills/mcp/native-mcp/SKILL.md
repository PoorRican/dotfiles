---
name: native-mcp
description: "Configure Hermes native MCP servers and diagnose discovery, transport and security pitfalls."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [MCP, Tools, Integrations]
    related_skills: [mcporter]
---

# Native MCP

Hermes discovers configured MCP servers and exposes their tools in the agent. A server can fail discovery independently, leaving its tools unavailable even when the agent starts normally.

- Configure servers under `mcp_servers` in `~/.hermes/config.yaml`; use a command for stdio or a URL for HTTP. If both are provided Hermes selects HTTP rather than rejecting the entry.
- Stdio servers inherit a filtered environment, not all shell credentials. Pass required variables in the server's `env`; secret-source variables may also be inherited.
- Discovered tool names use the `mcp_{server}_{tool}` prefix, with punctuation normalized. If tools are missing, inspect startup connection errors and server configuration.
- MCP sampling allows a server to request model completions; disable it for untrusted servers with `sampling: { enabled: false }`.

Install the optional `mcp` Python package in the Hermes environment; without it discovery is silently disabled. Restart the agent after adding or removing a server: connections are persistent and there is no hot reload.

```yaml
mcp_servers:
  time:
    command: "uvx"
    args: ["mcp-server-time"]
    env:
      SERVICE_TOKEN: "your-token"
    timeout: 120
    connect_timeout: 60
  remote_api:
    url: "https://mcp.example.com/mcp"
    headers:
      Authorization: "Bearer your-token"
    sampling:
      enabled: false
```

`timeout` is the per-tool-call timeout; `connect_timeout` covers initial connection and discovery. HTTP requires the SDK's `mcp.client.streamable_http` support. Stdio subprocesses inherit a filtered baseline and `XDG_*`, configured `env`, and variables injected by an external secret source; account for those credentials when trusting a server.

Sampling is enabled by default. Per-server `sampling` also supports `model`, `max_tokens_cap`, `timeout`, `max_rpm`, `allowed_models`, `max_tool_rounds` and `log_level`; an empty `allowed_models` permits all models, and `max_tool_rounds: 0` disables the tool loop. Check startup logs and increase `connect_timeout` if discovery times out; upgrade the MCP package if HTTP transport support is missing.
