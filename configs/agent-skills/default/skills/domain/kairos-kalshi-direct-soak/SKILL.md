---
name: kairos-kalshi-direct-soak
description: "Run a live Kalshi collector soak in kairos-collector via direct-launch (bypassing start-soak.sh's removed Task-8 rollout harness). Use to verify common-v5 orchestrator/worker/compactor changes produce parquet + converged gauges against the live prod feed."
---

# Kairos Kalshi direct-launch soak

Verifies the common-v5 Kalshi path end-to-end (coordinator→redb catalog→projection→common UDS server→worker reconcile→parquet→compaction) against the **live prod** feed. Use when `start-soak.sh` is unusable (it needs the removed Task-8 `SOAK_CONTROL_PROTOCOL`/rollout-harness env after the legacy control_protocol selector was deleted).

## Prereqs
- Release binaries: `cargo build --release --bin collector-orchestrator --bin collector-worker --bin collector-compactor` (run from the worktree; incremental ~20s).
- Credentials (gitignored): symlink from the main checkout into the worktree, then remove at teardown:
  `ln -sf /home/swe/kairos/kairos-collector/.env .env` and `ln -sf /home/swe/kairos/kairos-collector/.kalshi_api_key.pem .kalshi_api_key.pem`
- Config: `defaults/collector.testing.toml` (data_dir `/tmp/kairos-collector-testing`, orchestrator metrics `127.0.0.1:9462`, compactor `9461`, workers `kalshi.crypto`→`9400`, `kalshi.sports`→`9401`). It has NO `control_protocol` keys, so it parses post-removal.

## CLIs (all take `--config`; from the worktree cwd)
- `./target/release/collector-orchestrator --config <cfg> --instance kalshi`
- `./target/release/collector-compactor --config <cfg>`
- `./target/release/collector-worker --config <cfg> --instance kalshi.crypto` (and `kalshi.sports`)

## Launch
```
LOGS=/tmp/kalshi-soak-logs; DATA=/tmp/kairos-collector-testing
rm -rf "$DATA" "$LOGS"; mkdir -p "$LOGS"
set -a; . ./.env; set +a; export KALSHI_DEMO=false      # live prod
CFG=defaults/collector.testing.toml
nohup ./target/release/collector-orchestrator --config $CFG --instance kalshi >"$LOGS/orch.log" 2>&1 & echo $! >"$LOGS/orch.pid"
sleep 6   # orchestrator must bind the common socket + preload the engine first
nohup ./target/release/collector-compactor --config $CFG >"$LOGS/compactor.log" 2>&1 & echo $! >"$LOGS/compactor.pid"
nohup ./target/release/collector-worker --config $CFG --instance kalshi.crypto >"$LOGS/wcrypto.log" 2>&1 & echo $! >"$LOGS/wcrypto.pid"
nohup ./target/release/collector-worker --config $CFG --instance kalshi.sports >"$LOGS/wsports.log" 2>&1 & echo $! >"$LOGS/wsports.pid"
```

## GOTCHAS
- **`$!` captures the nohup WRAPPER pid; the real binary is pid+1.** A `kill -0 $!` liveness check falsely reports DEAD. Verify liveness with `ps -eo pid,etimes,comm | grep collector-` instead.
- Run ~150s for catalog discovery (REST `refresh_rps=5`, expect early transient 429s — normal for this profile) + ≥2 flush cycles (`max_segment_age_secs=60`, flush 30s).
- The testing profile reliably hits Kalshi REST 429s at startup; data still flows via WS after the catalog binds — not a failure by itself.

## Capture (before teardown; logs live OUTSIDE data_dir so wipe keeps them)
- Parquet by dataset: `find "$DATA/kalshi" -name '*.parquet' | grep -oE '/(orderbook_deltas|orderbook_snapshots|trades|tickers)/' | sort | uniq -c` (trades/tickers are low-frequency — often absent in a short window; not a path failure).
- Pending sealed segments (want 0 after drain): `find "$DATA/_landing" -name '*.seg' | wc -l`
- Worker common gauges: `curl -s 127.0.0.1:9400/metrics | grep common_control_` → want `reconcile_success=1`, `connected=1`, non-zero `reconciled_bindings`.
- Orchestrator: `curl -s 127.0.0.1:9462/state/health` → non-zero catalog_markets, `kalshi_common_projection_ready:true`; `curl -s 127.0.0.1:9462/state/version` → `common_protocol_version:5` (no legacy `protocol_version`).
- Error signals: `grep -cE "OrderbookSequenceGap|reconnected attempt=1|panic" "$LOGS"/w*.log`

## Teardown (mandatory)
```
pkill -INT -f 'target/release/collector-'; sleep 3; pkill -KILL -f 'target/release/collector-'
rm -rf "$DATA" "$LOGS"; rm -f .env .kalshi_api_key.pem   # remove cred symlinks
git status --short --untracked-files=all   # confirm no cred/scratch leak
```

## Notes
- The soak proves data production but CANNOT validate the liveness/boundary breach gates (no breach fires when data flows) — prove those by unit test/code inspection.
- Soak scripts/pkill target `target/release/collector-*` — do NOT run concurrently with another soak profile; read-only reviewer subagents are unaffected.
