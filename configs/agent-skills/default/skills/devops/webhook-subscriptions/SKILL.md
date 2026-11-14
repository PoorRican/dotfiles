---
name: webhook-subscriptions
description: "Configure and troubleshoot Hermes webhook subscriptions and direct event delivery."
version: 1.1.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [webhook, events, automation, integrations, notifications, push]
---

# Webhook subscriptions

Hermes webhook subscriptions turn external POSTs into agent runs or direct notifications. The webhook platform and gateway must be enabled and reachable by the sender before delivery can work.

If the webhook platform is disabled, run `hermes gateway setup` to enable it and configure its listener and secret, then start or restart the gateway. Check gateway status and logs if it does not start.

- `hermes webhook subscribe` creates a route; its help describes event filters, payload prompt fields, delivery, and secrets. Configure the sender with the returned URL and secret, and protect the secret.
- A prompt can reference nested payload fields with `{dot.notation}`; without a prompt the payload becomes agent input.
- For forwarding without an agent run, `--deliver-only` sends the rendered prompt directly and requires a real delivery target, not `log`.
- If delivery fails, distinguish gateway reachability, signature mismatch and event-filter mismatch; `hermes webhook test` tests the route. Static configured routes cannot be overwritten by dynamic subscriptions.

Check `hermes webhook list` first. If disabled, `hermes gateway setup` configures the platform; restart with `systemctl --user restart hermes-gateway` or run `hermes gateway run`. The default listener health check is `curl http://localhost:8644/health`.

```bash
hermes webhook subscribe github-issues \
  --events "issues" \
  --prompt "Issue #{issue.number}: {issue.title}; action: {action}" \
  --description "Triage new issues" \
  --skills "github-code-review" \
  --deliver telegram \
  --deliver-chat-id "12345"
hermes webhook test github-issues --payload '{"issue":{"number":1,"title":"Example"},"action":"opened"}'
hermes webhook remove github-issues
```

`--secret` supplies a custom subscription secret; otherwise one is generated. Configure the sender to use the returned URL, secret, JSON content type and matching events. Direct delivery adds `--deliver-only`; successful delivery returns 200 and target failure 502. Signatures, rate limits and idempotency still apply.

Dynamic subscriptions persist in `~/.hermes/webhook_subscriptions.json` and are hot-reloaded by the adapter. For signature failures verify the sender's secret; GitHub uses `X-Hub-Signature-256`, GitLab `X-Gitlab-Token`. A sender outside the local network needs a reachable endpoint or tunnel.
