---
name: kairos-ideation-slate-workflow
description: "Run a multi-subagent, pressure-tested trading-strategy ideation round in kairos-research (workflowz style): source scouts → axis-pinned ideators → synthesizer with IRC verdict loop → adversarial reviewers → final critic, ending in a committed docs/ideas/ slate. Use when asked to ideate/refresh an experiment slate or run a round-N ideation campaign."
---

# Kairos ideation-slate workflow

Proven twice (Round 1 `e59312e` 2026-07-13, Round 2 `873ac9f` 2026-07-16). Produces a slate of falsifiable experiment CARDS — never edge claims. Forbidden verdicts: "market is efficient", "no edge exists".

## Stage 0 — inline scoping (never delegated)
1. Check whether a prior slate exists in `docs/ideas/` — if yes, this round is round-N: prior cards become the ANTI-RHYME reference and the new round must rotate axes (edge-hunting-mentality orthogonality menu).
2. Build the source manifest inline: repo docs, `docs/data/`, `docs/superpowers/{plans,specs}`, `experiments/` + `src/`, `/var/tmp/compendium/**`, `experiments/_cache/**`, project wiki (`/home/swe/wikis/project-kairos/project-kairos` — Notes/ may have malformed frontmatter dates; enumerate, don't just date-grep), `../kairos-context`, memory digest. Source exhaustion is a completion criterion.
3. Write `local://<round>-shared-context.md`: goal, hard constraints (lake availability!), the MANDATORY card schema (hypothesis/signal; counterparty; universe+cadence; entry/exit; data+runnable-now flag; fees; metrics+baselines; validation; kill criteria; confounds; sources), fee facts, product semantics, measured-surface digest, prior-slate one-liners, axis menu.

## Stage 1 — extraction (scout agents, parallel)
One scout per source cluster. Scouts are READ-ONLY → their deliverable is their final message, consumed downstream via `agent://<Name>` URIs. Require sections: Inventory covered / Evidence atoms (number+N+citation) / Experiment seeds / Contradictions / Coverage gaps. Prior-slate scout additionally produces a "frontier analysis" of unused axes.

## Stage 2 — ideation (full `task` agents, parallel; NOT scouts — reasoning depth matters)
One ideator per axis lens (structural, carry/vol/RV, forecast/info, behavioral, execution/capacity), each pinned to DISJOINT assigned frontier items so they don't converge. Each returns 5–8 schema-complete cards + self-audit + considered-and-discarded list.
**Delivery hardening (bit us once):** require every ideator to WRITE the full card set to `local://<round>-cards-<lens>.md` AND return it inline — otherwise a final-message-summary strands the cards in the transcript. If one slips through, wake it via IRC and have it write the file.

## Stage 3 — synthesis + review loop (the user-mandated message-back)
- Spawn ONE synthesizer (`task`): merges/dedupes/renumbers into tiers (P0 = runnable-now on local data when lake is down; P1 lake-gated; P2 blocked), writes `local://<round>-draft.md`, DMs Main "DRAFT READY", then BLOCKS on `irc wait`.
- **Deadlock-proof verdict contract:** every reviewer MUST DM the synthesizer an explicit verdict (`VERDICT <name>: PASS/FAIL/VAGUE per card + DOC findings`) even if all-PASS; synthesizer counts N verdicts with a bounded-timeout fallback (4×15min, then proceed + tell Main). Never "silent on pass".
- Spawn 4 reviewers in one batch after DRAFT READY: causality/leakage, execution realism (fees exact: `F(c)=ceil(7c(100−c)/10000)` per contract, ceiling per-order; maker FIFO; adverse selection), statistics/falsifiability (verify runnable-now claims against the offline catalog BY OPENING FILES), novelty/anti-rhyme (reads prior slate + all lens files; checks synthesis fidelity + 100% card accounting).
- Synthesizer routes cards with ≥2 independent VAGUE verdicts BACK to originating ideators via IRC (they're idle/wakeable) for concrete fixes; incorporates, writes final, DMs "FINAL READY".
- **Appended-fix desync class (bit us once):** ideators sometimes deliver fixes as APPENDED sections instead of in-place edits; require the synthesizer to verify per routed card that the fix text is PRESENT IN THE CARD BODY and report a per-card INCORPORATED yes/no checklist.

## Stage 4 — final critic + delivery (parent owns closure)
1. One final critic (`task`): source exhaustion vs manifest, accounting integrity (all candidates dispositioned, tier counts, prior-slate crosswalk), schema spot-checks, hygiene (no forbidden verdicts, un-reproduced claims caveated, no lake-connection instructions), style vs prior slate register. Verdict ACCEPT/REJECT with BLOCKER/MAJOR/MINOR findings.
2. Route findings back to the synthesizer; independently verify each BLOCKER fix yourself via grep/raw reads of the corrected file.
3. Copy the corrected `local://` file into `docs/ideas/<date>-<name>.md`, `cmp` for byte identity, run `uv run pytest && uv run pyrefly check && uv run ruff check .`, commit with EXPLICIT staging (`git add docs/ideas/<file>` — never `-A`, pre-existing untracked files must not be swept).

## Editing traps (cost real corruption once)
- read/grep DISPLAY-truncates long lines ("…", 512/768-char caps). Never paste displayed text into a patch — re-read `:raw` first. grep MATCHES raw bytes, so a positive grep is valid evidence even when display truncates.
- `apply_patch` on markdown bullet lines is ambiguous: a patch line starting `- **Field:** …` parses as a DELETION, and a prefix-only match can silently eat the rest of the line. For long single-line markdown edits use Python exact string replace: assert anchor count==1, replace, assert all expected fragments still present.

## Doc shape that worked
Decision (start-today cards) / How produced / Portfolio non-negotiables / Priority queue table / cards per tier / Shared gates / Ordered execution (offline-now phase first when lake is down) / Known blockers (carried + updated) / Review outcomes (per-reviewer counts + per-card action + unresolved disagreements) / prior-round crosswalk / Dropped-in-synthesis audit (every candidate accounted) / Source universe & provenance. Keep card IDs stable after review drops/merges (document gaps) so cross-references survive.
