---
name: kairos-lake-characterization-campaign
description: "Orchestrate a parallel multi-agent descriptive characterization of a Kairos lake market vs reference data (e.g. Kalshi family vs pbp), producing a verified compendium doc — use when asked to \"characterize/describe\" a market surface with low-reasoning (sonic) subagents."
---

# Kairos lake characterization campaign (orchestrator pattern)

Proven 2026-07-11 on MLB (docs/compendium-2026-07-11-mlb.md): 8 parallel sonic agents, ~950-row instance catalogs, zero repo breakage. Works because low-reasoning agents get precomputed data + a strict contract, and the orchestrator owns scoping, estimator corrections, and verification.

## Phase 0 — orchestrator does the prerequisites INLINE (never delegate these)
1. Env: eval kernels do NOT inherit shell env. Dump creds once: `env | grep '^KAIROS_LAKE_' > /var/tmp/<campaign>/lake.env`; every script parses that file into os.environ before `attach_lake()`.
2. Census live: `SHOW ALL TABLES`, DESCRIBE key tables, per-family row counts (full-table GROUP BY on ducklake is seconds), date range, MISSING dates (generate_series anti-set), sentinel distributions (e.g. Kalshi: bid=0 / ask=1e6 = empty side, never NULL, never crossed).
3. Build shared parquets so agents never repeat heavy scans:
   - `game_market_map.parquet`: latest universe row per instrument (ROW_NUMBER over observed_at) × xwalk (max match_confidence) × latest-resolved game_window per window_type × dim table. Include results, windows, team linkage, strike text.
   - Quote + trade minute bars per instrument: chunk by `date` partition (~10 dates/chunk), arg_max(last values), lo/hi mid computed ONLY over two-sided quotes, per-chunk COPY TO parquet. ~112M rows → ~40s.
4. Write `/var/tmp/<campaign>/CONTRACT.md`: connection boilerplate verbatim; DuckDB caps (memory_limit 2GB, temp_directory /var/tmp spill NOT /tmp, max_temp_directory_size 4GB, preserve_insertion_order=false, threads=3 so N agents ≤ machine threads); prohibited heavy tables; mandatory family_id+date filters on raw scans; price/qty scaling; sentinels; clock-offset caveat; output format (Data note → numbered findings, each with stats table + ≥5-row instance catalog + counter-examples + "open questions"); "every stat carries its N"; "prove absence by enumeration".
5. Dump orchestrator-verified numbers to `census_precomputed.md` so agents embed instead of recomputing.

## Phase 1 — fan out one sonic per thematic section, ALL in one task batch
- Sections = user's asks mapped to disjoint themes (census/microstructure, trajectories/flips, drift/reversals, event-conditioned reactions, quiet moves, derivative complexes, cross-market, rare-event instances, + orchestrator-written synthesis).
- One section OWNS clock calibration. CRITICAL anchor-semantics lesson: event-feed timestamps may stamp play COMPLETION, not start — decompose the market-reaction offset against BOTH boundary timestamps (start & end) and correlate with event duration BEFORE interpreting any offset as feed latency (MLB: the famous −26s "lag" was the home-run trot; real reaction = start +0.4s). Never conflate anchor semantics with publication latency; if ingest is batch, publication latency is UNMEASURED — say so, never guess a number.
- Specs must be mechanical: near-complete SQL/recipes, exact output paths, minimum catalog sizes, explicit null-result expectations.

## Phase 2 — steer live via irc (watch for these recurring bugs)
- Estimator survivorship: any aggregate over "currently two-sided" instruments drops settled/ITM legs (implied totals collapse; convergence metrics die at extremes). Fix = restore known-settled mass (runs scored → P=1) or switch to bid/last-trade near settlement.
- Additive-floor conflation (the dual bug of the fix above): once E = known_floor + Σ P(live), the floor only ratchets UP, so "rise then fall" reversal shapes are mechanically manufactured by floor growth followed by ordinary expectation decay — only the fall-then-rise direction is a defensible anomaly. Any count that jumps when a coverage/gap-fill gate is loosened is estimator-sensitive: label it an upper bound, report the shape split, never let "genuine" attach without instance-level eyeballing at the final gate.
- Stitched thresholds: catalog pass vs aggregate pass computed with different filters → self-contradictory counts; force ONE pinned definition recomputed from one table.
- Score/context label joins: before/after state must come from adjacent complete-PA rows by canonical order, never subtraction or mid-PA rows; validate catalogs (score strictly increased etc.).
- Skill-split reference trap: if a taker/participant skill partition shows BOTH groups losing vs mid (e.g. flow-pushers AND flow-faders underwater at +5/+15min), the reference price is broken (displaced mid at strong-move minutes, strike-decay selection), not the traders — demand a fill-level test before any "uninformed flow" upgrade from prior to result. Related: contemporaneous-direction agreement is NOT a skill metric, and two-leg/ladder families need INSTRUMENT-level (not family-mean) signed moves to avoid anti-correlation degeneracy.
- Exposure normalization: any "X clusters near events" claim over a dense event stream (pitch cadence) is uninformative as a share — normalize to rate per exposure-time at each event-relative offset, or per event-class count.

## Phase 3 — verify, assemble, deliver
- Read every section fully; spot-check 2-3 headline numbers by independent recount against the lake (expect ±1 fill-convention wobble; exact match on tail counts). Extend the spot-check to any number that changed after an irc-driven estimator correction — post-correction counts are exactly the ones nobody instance-checked.
- Assembler sonic: mechanical merge with an ENUMERATED fix list + integrity gate: per-section `###` heading and catalog-row counts input vs output must match exactly.
- Orchestrator writes the synthesis section personally (cross-cutting claims + methods caveats + downstream agenda), citing section numbers and marking independently recomputed numbers.
- Deliver: cp to docs/<campaign>.md, commit just the doc; leave CSVs/parquets in /var/tmp as claim-backing; rm duckdb spill dirs.
- Follow-up challenges: map the current doc with a read-only scout (line anchors + verbatim quotes) before patching a user-rewritten file; keep follow-up findings as dated, clearly-labeled blocks appended to the affected findings.

## Channel-fidelity ladder (Kalshi)
minute BARS < tickers ticks < orderbook_snapshots (sparse ground truth) < orderbook_delta replay. Tickers = 99.3%-exact BBO proxy but lags the book channel +91ms median and misses ~2/3 of sub-second episodes; validate delta replays against the delta channel's OWN snapshots (a cross-channel tickers gate fails on skew even when reconstruction is perfect); replay via transcode seed_snapshot/apply_delta(clamp_underflow) grounded STRICTLY before window start.

## Machine safety (60GB box, tight)
Check `free -g` before sizing the fan-out; N agents × (memory_limit + ~0.5GB python) must fit `available`. Spill on /var/tmp (real disk), never /tmp (tmpfs). Chunk every raw scan by the `date` partition column.
