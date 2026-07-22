---
name: local-columnar-data-inspection
description: Inspect local columnar/partitioned datasets (Parquet, SQLite staging/workspace DBs, JSONL metadata exports) to answer data-availability, earliest/latest timestamp, schema, and provenance questions without assuming labels are obvious.
---

# Local Columnar Data Inspection

Use this skill when the user asks what data exists in a local directory, especially for compacted/uncompacted Parquet, consolidated exports, partitioned filesystem datasets, or metadata snapshots. Typical questions: "what is the earliest data we have?", "is X covered?", "which partitions contain Y?", "what rows/schemas are in this export?"

## Core approach

1. **Start from the user's target scope, not filename guesses.**
   - If the user points to a directory, enumerate top-level directories and known export manifests/READMEs.
   - For consolidated datasets, look for staging/workspace artifacts (`*.sqlite`, `*.duckdb`, profiles/stats JSON, README) as well as Parquet files.
   - Do not assume relevant data is labeled with the user's domain term (e.g. NBA data may be under generic Kalshi Sports partitions or titles like "Pro Basketball").

2. **Identify authoritative metadata first.**
   - Read local README/profile/stats files when present.
   - Inspect SQLite staging/workspace DBs with read-only connections (`file:path?mode=ro`) to discover tables, columns, row counts, row_source values, and candidate filters.
   - Prefer metadata indexes/workspaces over recursively reading millions of Parquet files when they contain the same event/market descriptors.

3. **Build broad-but-controlled domain filters.**
   - Combine exact IDs/tickers with title/rules synonyms.
   - Watch for substring false positives: `NBA` can appear inside unrelated strings (`...BNBA...`, artist names, `WNBA`). Use exact series prefixes or exclusions when needed.
   - Keep separate answers for distinct interpretations, e.g. "NBA-related", "actual NBA game markets", "metadata only", and "Parquet/candle data".

4. **Verify data timestamps from the actual data files when asked about earliest/latest data.**
   - Metadata `open_time`/`close_time` answers market availability; Parquet column stats answer actual data coverage.
   - For candle Parquet, check timestamp columns such as `end_ts`, `ts`, `timestamp`, `time`, or other `*_ts` fields.
   - If no Parquet reader libraries are installed and installing packages would be inappropriate or blocked, parse Parquet footer metadata/statistics directly rather than stopping. See `scripts/parquet_footer_min_ts.py`.

5. **Report the path and interpretation.**
   - State the exact file or partition used to verify the answer.
   - Include the event/series/ticker/title and whether the timestamp came from metadata (`open_time`, `close_time`) or Parquet stats (`end_ts` min/max).
   - If there are multiple plausible "earliest" notions, provide a compact distinction instead of collapsing them into one ambiguous answer.

## Useful commands/patterns

### SQLite workspace inspection

```python
import sqlite3
con = sqlite3.connect('file:/path/to/workspace.sqlite?mode=ro', uri=True)
con.row_factory = sqlite3.Row
print(con.execute("select name,type from sqlite_master where type in ('table','view')").fetchall())
print(con.execute('pragma table_info(source_rows)').fetchall())
```

### Domain filtering pattern

```sql
where category = 'Sports'
  and row_source like 'kairos%'
  and (
    upper(coalesce(series_ticker,'')) glob 'KXNBA*'
    or upper(coalesce(series_ticker,'')) in ('KXCOACHOUTNBA','KXNEXTCOACHOUTNBA')
  )
  and upper(coalesce(series_ticker,'')) not glob 'KXWNBA*'
```

Adjust the prefix/synonyms to the domain; the lesson is to use structured columns first, then text fields only with exclusions.

## References

- `references/kairos-consolidated-parquet.md` — session example: finding earliest NBA-related data in consolidated kairos-collector/Kalshi parquet exports.
- `scripts/parquet_footer_min_ts.py` — dependency-free Parquet footer/statistics scanner for Unix timestamp columns.

## Pitfalls

- **Do not rely on filenames alone.** Relevant data can be encoded in event titles, series tickers, or partition directories rather than human-readable names.
- **Do not conflate metadata with data coverage.** An event may have event/market JSON but no candle Parquet.
- **Avoid broad substring matches without review.** `NBA` matching can include unrelated strings; `basketball` matching can include college basketball or WNBA.
- **Do not persist environment setup failures as rules.** Missing `pyarrow`, `duckdb`, or `parquet-tools` is a local setup fact; use an alternate inspection path or install only when allowed.

## Verification checklist

- [ ] Identified the dataset/export root and relevant metadata artifacts.
- [ ] Confirmed row schema/table names and row_source/provenance.
- [ ] Used a domain filter that avoids obvious false positives.
- [ ] Verified earliest/latest timestamps against the appropriate source (metadata vs Parquet stats).
- [ ] Reported exact path(s), timestamp(s), and the meaning of each timestamp.
