# Kairos consolidated Parquet: earliest NBA-related data example

Session context: user asked for the earliest NBA data in `/home/swe/data`, then clarified that the target was consolidated kairos-collector data and that NBA data might not be labeled `NBA`; it could be compacted or uncompacted Parquet.

## Dataset artifacts encountered

Relevant root:

```text
kalshi-data/unified-data-raw-20260313/
```

Useful artifacts:

```text
README.md
flattened/market_metadata_canonical_blunt.workspace.sqlite
flattened/market_metadata_by_source.profile.md
source_snapshots/kairos-collector/data/kalshi/<YYYY>/<MM>/<EVENT>/...
```

`market_metadata_canonical_blunt.workspace.sqlite` had table `source_rows` with consolidated market rows and columns including:

```text
row_source, market_ticker, event_ticker, series_ticker, event_title,
market_title, category, open_time, close_time, expiration_time,
expected_expiration_time, updated_at_ts, partition_year, partition_month
```

The source snapshot stored event JSON plus optional candle Parquet under paths such as:

```text
source_snapshots/kairos-collector/data/kalshi/2030/01/KXNBATEAM-30/
  event.json
  markets.json
  candles_1m/canonical.parquet
  candles_1h/canonical.parquet
  candles_1d/canonical.parquet
```

## Filtering lesson

Start structured, then broaden carefully. A practical NBA-ish filter for this dataset was:

```sql
category='Sports'
AND row_source LIKE 'kairos%'
AND (
  upper(coalesce(series_ticker,'')) GLOB 'KXNBA*'
  OR upper(coalesce(series_ticker,'')) IN ('KXCOACHOUTNBA','KXNEXTCOACHOUTNBA')
)
AND upper(coalesce(series_ticker,'')) NOT GLOB 'KXWNBA*'
```

A broader exploratory filter also searched titles/rules for `NBA` and `PRO BASKETBALL`, but that produced false positives. `basketball` alone included college basketball.

## Findings from the session

Different notions of "earliest" gave different answers:

1. **Earliest NBA-related Parquet/candle data overall**
   - Timestamp source: min `end_ts` from Parquet footer stats.
   - Timestamp: `2024-12-19T16:00:00Z`.
   - Event: `KXNBATEAM-30` / `KXNBATEAM`.
   - Title: `Will the NBA add a new team before 2030?`.
   - File:

     ```text
     kalshi-data/unified-data-raw-20260313/source_snapshots/kairos-collector/data/kalshi/2030/01/KXNBATEAM-30/candles_1m/canonical.parquet
     ```

   - Metadata market open was `2024-12-19T15:00:00Z`; first one-minute candle ended at `2024-12-19T16:00:00Z`.

2. **Earliest NBA event by market close/partition date**
   - Event: `KXNBAALLSTAR-25`.
   - Title: `Pro Basketball All Star Game`.
   - Open: `2025-02-15T15:00:00Z`.
   - Close: `2025-02-17T04:48:12.951904Z`.
   - Path:

     ```text
     kalshi-data/unified-data-raw-20260313/source_snapshots/kairos-collector/data/kalshi/2025/02/KXNBAALLSTAR-25/
     ```

   - Important: this had event/market JSON in the snapshot but no candle Parquet at that path.

3. **Earliest NBA game-market metadata**
   - Event: `KXNBAGAME-25APR15ATLORL`.
   - Title: `Basketball Play-In: Atlanta vs Orlando`.
   - Open: `2025-04-14T18:00:00Z`.
   - Close: `2025-04-16T02:39:09.736516Z`.

4. **Earliest NBA game-market candle Parquet specifically**
   - Timestamp source: min `end_ts` from Parquet footer stats.
   - Timestamp: `2026-02-05T02:00:00Z`.
   - Event: `KXNBAGAME-26FEB06INDMIL`.
   - Title: `Indiana at Milwaukee`.
   - Open: `2026-02-05T01:07:00Z`.
   - File:

     ```text
     kalshi-data/unified-data-raw-20260313/source_snapshots/kairos-collector/data/kalshi/2026/02/KXNBAGAME-26FEB06INDMIL/candles_1m/canonical.parquet
     ```

## Output style that worked

Provide a compact set of interpretations and a clear shortest answer, e.g.:

> Shortest answer: the earliest NBA-related Parquet data is `2024-12-19T16:00:00Z`, from `KXNBATEAM-30`.

Then list caveats for metadata-only vs game-market vs Parquet-backed answers.
