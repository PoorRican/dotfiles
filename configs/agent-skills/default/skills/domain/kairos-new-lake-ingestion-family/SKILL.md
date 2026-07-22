---
name: kairos-new-lake-ingestion-family
description: "Add a new REST/archive-sourced historical ingestion family (new venue/namespace) to kairos-data-pipeline: adapters package, DuckLake DDL/views/migrations, partition_replace assets, checks, and gates."
---

# New REST/Archive Lake Ingestion Family (kairos-data-pipeline)

Repeatable checklist for adding a venue-historical asset family (proven by the 2026-07-12 Binance/Coinbase/Polymarket build, PR #134). The canonical template is the Kalshi historical chain.

## 1. Pure-domain adapters
- Venue parsing/HTTP lives in a `packages/<x>-adapters` workspace package (or a submodule of `packages/crypto-adapters` for market-data venues) — zero Dagster imports, lazy `__getattr__` in `__init__.py`.
- Reuse `crypto_adapters.http.HttpGetter` (token-bucket RPS, Retry-After backoff, `HttpStatusError.status` for 404-tolerance, browser UA — Cloudflare 1010-bans non-browser UAs) and `crypto_adapters.field_contract.FieldContract`.
- Polars schema constants MUST be `pl.Schema({...})`, never `dict[str, pl.DataType]` with dtype classes — the pre-commit pyrefly hook (which receives staged filenames, stricter than project-wide check) rejects the dict form.
- Take client deps as `Protocol`s so unit tests pass stubs without subclassing.
- Field contracts + golden fixtures: fixtures captured LIVE via a committed `tests/fixtures/<venue>/refresh_fixtures.py`; coverage test fails on any unaccounted source field; WARN runtime drift check samples stored `*_json` rows.

## 2. DuckLake DDL (four registration points — miss one and bootstrap silently skips)
1. `sql/schema/<ns>_schema.sql` (CREATE SCHEMA/TABLE IF NOT EXISTS baseline).
2. `defs/lake_ddl.py`: `_SCHEMA_SQL_FILES` dict AND the `namespaces` default tuple.
3. `defs/lake_views.py`: `_VIEW_SQL_FILES` tuple + `sql/views/<ns>_views.sql` (`v_<table>`, derived TIMESTAMPTZ via `make_timestamp(ns // 1000) AT TIME ZONE 'UTC'`).
4. `lake_bootstrap.py`: the `schema_name IN (...)` summary list.
Plus an operator migration `sql/migrations/YYYY-MM-DD-NNN-*.sql` mirroring the DDL with the standard header (Scope/Rerun safety/Verification with expected col counts filtered `table_name NOT LIKE 'v_%'`/Views/Live application/Migration log). NEVER applied by the implementer; migration-log PRs go to kairos-context branch `okf`.

## 3. Assets
- Use `partition_replace_asset` (`defs/ops/partition_replace.py`); it accepts `partitions_def=None` for unpartitioned full-replace snapshots (`delete_where_sql="TRUE"`).
- Constants per module: `KEY_PREFIX=["<ns>","historical"]`, `GROUP="<ns>_historical"`, `BackfillPolicy.multi_run(1)`, `kinds={"ducklake"}`, per-venue `prepare_pool`, NO automation_condition (UI backfills only).
- NEVER `from __future__ import annotations` in modules annotating Dagster context params. Bare `@dg.asset_check` globals auto-discover even beside a sibling module with `@dg.definitions`.
- Guards: raise on impossible-empty elapsed partitions (all-404 archive, zero products); do NOT raise where sparse days are legitimate — verify live before choosing (e.g. Polymarket crypto tag had 2 events on 2025-01-15).
- Blocking `_<table>_required_present(conn, *, partition) -> tuple[bool, dict]` pure helper + thin wrapper; test against constraint-free in-memory DuckDB mirrors (plain DuckDB enforces NOT NULL, DuckLake doesn't).

## 4. Wiring + gates
- Resources in `defs/resources.py` (one ConfigurableResource per venue; creds checked at `.client()` time so the code location loads without them; PEM secrets stored `\n`-escaped, unescape with `.replace("\\n", "\n")`).
- Root `pyproject.toml`: deps, workspace members, uv.sources, pytest testpaths, coverage source, ruff known-first-party. Then `uv sync --all-packages`.
- Verify: focused pytest, `uv run --all-packages pyrefly check`, `ruff check`, `uv run dg check defs`, plus `@pytest.mark.live` smokes per venue (skipif when creds absent).
- Update `docs/STORAGE_SCHEMAS.md` (namespace bullet + table section) and the coverage snapshot in `src/kairos_data_pipeline/CLAUDE.md`.

## 5. Committing + pushing
- Run `uv run ruff format .` BEFORE committing; the ruff-format hook fails the first attempt if it reformats.
- Cross-file-coupled work (untracked modules depending on unstaged tracked edits) must go in ONE commit — pre-commit's stash reverts unstaged tracked mods but keeps untracked files, breaking piecemeal commits.
- Runtime-prose word trap: `tests/docs/test_ducklake_operations_docs.py` forbids the lowercase literal `"checksum"` (and `sql/migrations`, `MigrationRegistry`, ...) in ALL `src/kairos_data_pipeline/**/*.py` text INCLUDING docstrings (case-sensitive; only surfaces in the pre-push full-suite hook). Write `.CHECKSUM sidecar` / `SHA-256-verified` / `integrity error` instead; reword prose, never edit the guard list.
- PR flow: branch off local master state, `git reset --hard origin/master` on master, push branch (pre-push runs the FULL suite), `gh pr create --base master`, then watch CI (live-smoke job is schedule-only and skips on PRs).

## 6. Post-merge operator steps
Compile them into a dated `docs/YYYY-MM-DD-<family>-rollout.md` checklist (precedent: `docs/2026-07-12-crypto-historical-rollout.md`): image deploy + in-cluster `dg check defs`, secrets via kairos-infra, apply migrations live per DuckLake SOP (before/after snapshots + `duckdb_columns()` counts), `bootstrap_lake_views(conn)`, migration-log entry in kairos-context (`okf` base), `dagster instance concurrency set <pool> 1` (pool limit caps vendor RPS — token buckets are per-run), then UI backfills in dependency order.
