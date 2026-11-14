# Messaging another OMP session

`agent://` messaging is process-local: it reaches agents in the current spawn tree, not independent sessions.

| Need | Mechanism |
|---|---|
| Steer an existing interactive session and its agents | Host `/collab` and use a full-control link. |
| A program owns the session input and output | Launch `omp --mode rpc`; it cannot attach to an existing TUI. |
| Independent sessions need a durable peer channel | Implement an extension bridge on a Unix socket. |
| Send keystrokes to an existing pane without an extension | Use Tern pane injection; delivery has no receipt and terminal capture is not the transcript. |
| Resume an interrupted session and its agents | Use `omp --restore <session.jsonl>`; this resumes work rather than messaging the live process. |

## Collab

Host with `/collab` or `collab.autoStart: control`. Guests may prompt, interrupt, and use Agent Hub chat/kill/revive against the host's subagents.

```sh
omp collab list --json             # instanceId, pid, busy, access, inputRequired
omp collab link <instanceId-or-pid>  # full-control URL; --view for read-only
omp join "<roomId>.<key>"          # interactive only
```

Treat the full link as a credential. The local collab registry provides discovery and links, not a prompt-delivery API; scripted delivery needs the guest protocol (`packages/collab-web`).

## RPC

`omp --mode rpc` and `--mode rpc-ui` use NDJSON over stdio. Commands include `prompt`, `steer`, `follow_up`, `abort`, `abort_and_prompt`, `get_state`, `get_subagents`, `steer_subagent` and `cancel_subagent`. Turn completion arrives as `prompt_result` / `session_settled`; correlate responses by `id`, not emission order. RPC pins neutral defaults for task isolation, memory, advisor, async-job and auto-background settings; explicit `--config` and project config remain authoritative.

## Extension bridge

Place an extension in `<cwd>/.omp/extensions` or `~/.omp/agent/extensions`. Register handlers at load but initialize the socket after `session_start`: calling `pi.sendMessage` during load throws `ExtensionRuntimeNotInitializedError`.

```ts
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
export default function (pi: ExtensionAPI) {
  pi.on("session_start", async () => {
    // On socket message:
    pi.sendMessage(text, { deliverAs: "steer", triggerTurn: true, attribution: "agent" });
  });
}
```

`deliverAs` supports `steer`, `followUp`, `nextTurn`, and `aside`; `triggerTurn: true` starts a turn when idle. `pi.runEphemeralTurn` answers a peer from a context snapshot without injecting a live user message.

## Tern

```sh
tern new session workerA --cwd ~/workspace -- omp
tern ls --json
tern run workerA/omp "Please inspect the fixtures"
tern send workerA/omp paste "multi-line note"
tern wait workerA/omp --until idle=1500
tern capture workerA/omp --scrollback
```

An injected message while an OMP approval prompt is open can deny pending approvals and then steer the session. Gate on `tern wait --until idle` and check collab `inputRequired` before sending. OMP's native Tern integration queues mid-turn typing as steering; terminal capture is not the transcript tree and Tern delivery has no receipt.
