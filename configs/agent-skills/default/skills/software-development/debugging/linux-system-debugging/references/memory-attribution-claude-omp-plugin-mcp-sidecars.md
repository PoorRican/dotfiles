# Memory attribution: Claude/OMP plugin MCP sidecars

Use this when RAM is consumed by many `uvx`, `npm exec`, `awslabs.*-mcp-server`, `mcp-proxy-for-aws`, or `context7-mcp` processes.

## Symptom pattern

Multiple long-lived coding-agent sessions can each start plugin-provided MCP servers. With user-scope Claude Code plugins enabled, every active `claude` or OMP session may spawn its own sidecars, so memory usage multiplies by the number of stale sessions.

Common process names:

- `uv tool uvx awslabs.aws-iac-mcp-server@latest`
- `uv tool uvx awslabs.aws-pricing-mcp-server@latest`
- `uv tool uvx mcp-proxy-for-aws@... https://aws-mcp.<region>.api.aws/mcp ...`
- `npm exec @upstash/context7-mcp`
- child `python .../awslabs.aws-iac-mcp-server`
- child `node .../context7-mcp`

Typical parents:

- `claude`
- `/home/.../.local/share/claude/versions/...`
- `bun /home/.../.bun/bin/omp`

## Attribution workflow

1. List MCP-ish processes with parentage:

```bash
ps -eo pid,ppid,pgid,sid,user,stat,lstart,rss,comm,args \
  | awk 'tolower($0) ~ /aws-iac-mcp-server|aws-pricing-mcp-server|mcp-proxy-for-aws|context7-mcp|uv tool uvx/ {print}' \
  | sort -n
```

2. Check whether they come from Claude Code plugin MCP configs:

```bash
grep -R "awslabs.aws-iac-mcp-server\|awslabs.aws-pricing-mcp-server\|mcp-proxy-for-aws\|context7-mcp" \
  ~/.claude/plugins/cache ~/.claude/plugins/installed_plugins.json ~/.claude.json ~/.claude/settings.json 2>/dev/null
```

3. Inspect plugin `.mcp.json` files when present:

```bash
python -m json.tool ~/.claude/plugins/cache/claude-plugins-official/aws-dev-toolkit/*/.mcp.json
python -m json.tool ~/.claude/plugins/cache/claude-plugins-official/deploy-on-aws/*/.mcp.json
python -m json.tool ~/.claude/plugins/cache/claude-plugins-official/aws-core/*/.mcp.json
```

4. If settings are managed from dotfiles, verify the live symlink before editing:

```bash
readlink -f ~/.claude/settings.json
```

## Durable fix

Disable the plugin in Claude Code settings rather than only killing child processes. In `~/.claude/settings.json` or the dotfiles-backed source file, set entries under `enabledPlugins` to `false`, for example:

```json
"enabledPlugins": {
  "deploy-on-aws@claude-plugins-official": false,
  "aws-dev-toolkit@claude-plugins-official": false,
  "aws-core@claude-plugins-official": false
}
```

If the plugin is installed but disabled in settings, new Claude/OMP sessions should not spawn those plugin MCP servers. Existing sessions keep their already-started sidecars until the owning `claude`/`omp` process exits.

## Pitfalls

- Do not conclude a notebook or experiment kernel is responsible just because the project path is nearby; trace parent processes.
- Killing MCP children is only a temporary cleanup. Active Claude/OMP sessions may respawn them or lose plugin tools.
- Disabling a plugin in a symlinked dotfiles config affects new sessions immediately, but already-running sessions must be closed to reclaim memory.
- Some AWS plugins duplicate MCP servers: both `deploy-on-aws` and `aws-dev-toolkit` may define `awsiac`; `aws-core` may add a separate AWS proxy.
- Preserve unrelated local edits in `settings.json` when flipping plugin booleans.
