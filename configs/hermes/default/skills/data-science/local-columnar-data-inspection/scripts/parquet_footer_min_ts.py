#!/usr/bin/env python3
"""Dependency-free Parquet footer timestamp scanner.

Given one or more Parquet files or directories, parse Parquet metadata footers using
Thrift compact protocol and report min/max Unix-second timestamp statistics for
columns named end_ts, ts, timestamp, time, created_ts, or *_ts.

This is useful when pyarrow/duckdb/parquet-tools are unavailable and the question
can be answered from Parquet column statistics without reading row data.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import struct
from pathlib import Path
from typing import Any, Iterable

T_STOP = 0
T_BOOLEAN_TRUE = 1
T_BOOLEAN_FALSE = 2
T_BYTE = 3
T_I16 = 4
T_I32 = 5
T_I64 = 6
T_DOUBLE = 7
T_BINARY = 8
T_LIST = 9
T_SET = 10
T_MAP = 11
T_STRUCT = 12


def read_varint(buf: bytes, pos: int) -> tuple[int, int]:
    shift = 0
    result = 0
    while True:
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            return result, pos
        shift += 7


def zigzag(n: int) -> int:
    return (n >> 1) ^ -(n & 1)


def read_val(buf: bytes, pos: int, ttype: int) -> tuple[Any, int]:
    if ttype in (T_BOOLEAN_TRUE, T_BOOLEAN_FALSE):
        return ttype == T_BOOLEAN_TRUE, pos
    if ttype == T_BYTE:
        return struct.unpack_from("b", buf, pos)[0], pos + 1
    if ttype in (T_I16, T_I32, T_I64):
        raw, pos = read_varint(buf, pos)
        return zigzag(raw), pos
    if ttype == T_DOUBLE:
        return struct.unpack_from("<d", buf, pos)[0], pos + 8
    if ttype == T_BINARY:
        length, pos = read_varint(buf, pos)
        return bytes(buf[pos : pos + length]), pos + length
    if ttype in (T_LIST, T_SET):
        header = buf[pos]
        pos += 1
        size = header >> 4
        elem_type = header & 0x0F
        if size == 15:
            size, pos = read_varint(buf, pos)
        values = []
        for _ in range(size):
            value, pos = read_val(buf, pos, elem_type)
            values.append(value)
        return values, pos
    if ttype == T_MAP:
        size, pos = read_varint(buf, pos)
        if size == 0:
            return [], pos
        type_byte = buf[pos]
        pos += 1
        key_type = type_byte >> 4
        val_type = type_byte & 0x0F
        items = []
        for _ in range(size):
            key, pos = read_val(buf, pos, key_type)
            value, pos = read_val(buf, pos, val_type)
            items.append((key, value))
        return items, pos
    if ttype == T_STRUCT:
        return read_struct(buf, pos)
    raise ValueError(f"unknown Thrift compact type {ttype} at byte {pos}")


def read_struct(buf: bytes, pos: int = 0) -> tuple[dict[int, Any], int]:
    out: dict[int, Any] = {}
    last_fid = 0
    while True:
        header = buf[pos]
        pos += 1
        ttype = header & 0x0F
        if ttype == T_STOP:
            break
        delta = header >> 4
        if delta == 0:
            raw, pos = read_varint(buf, pos)
            fid = zigzag(raw)
        else:
            fid = last_fid + delta
        last_fid = fid
        value, pos = read_val(buf, pos, ttype)
        out[fid] = value
    return out, pos


def b2s(value: Any) -> Any:
    if isinstance(value, bytes):
        try:
            return value.decode("utf-8")
        except UnicodeDecodeError:
            return value.hex()
    return value


def parse_footer(path: Path) -> dict[int, Any]:
    with path.open("rb") as f:
        f.seek(-8, 2)
        trailer = f.read(8)
        if trailer[4:] != b"PAR1":
            raise ValueError("not a Parquet file")
        footer_len = struct.unpack("<i", trailer[:4])[0]
        f.seek(-8 - footer_len, 2)
        footer = f.read(footer_len)
    meta, _ = read_struct(footer, 0)
    return meta


def int_from_stats(raw: bytes | None, parquet_type: int) -> int | None:
    if raw is None:
        return None
    if parquet_type == 2:  # INT64
        return struct.unpack("<q", raw)[0]
    if parquet_type == 1:  # INT32
        return struct.unpack("<i", raw)[0]
    return None


def is_timestamp_column(name: str) -> bool:
    return name in {"end_ts", "ts", "timestamp", "time", "created_ts"} or name.endswith("_ts")


def scan_file(path: Path, min_epoch: int, max_epoch: int) -> list[dict[str, Any]]:
    meta = parse_footer(path)
    hits: list[dict[str, Any]] = []
    for rg_index, row_group in enumerate(meta.get(4, [])):  # FileMetaData.row_groups
        for col_chunk in row_group.get(1, []):  # RowGroup.columns
            col_meta = col_chunk.get(3, {})  # ColumnChunk.meta_data
            path_names = [b2s(x) for x in col_meta.get(3, [])]  # path_in_schema
            if not path_names:
                continue
            column = str(path_names[-1])
            if not is_timestamp_column(column):
                continue
            parquet_type = col_meta.get(1)
            stats = col_meta.get(12, {})
            # Prefer min_value/max_value (fields 6/7), fallback to legacy min/max (1/2).
            min_raw = stats.get(6) or stats.get(1)
            max_raw = stats.get(7) or stats.get(2)
            min_v = int_from_stats(min_raw, parquet_type)
            max_v = int_from_stats(max_raw, parquet_type)
            if min_v is None and max_v is None:
                continue
            if min_v is not None and not (min_epoch <= min_v <= max_epoch):
                continue
            if max_v is not None and not (min_epoch <= max_v <= max_epoch):
                continue
            hits.append(
                {
                    "file": str(path),
                    "row_group": rg_index,
                    "column": column,
                    "min_epoch": min_v,
                    "min_utc": dt.datetime.fromtimestamp(min_v, tz=dt.timezone.utc).isoformat() if min_v is not None else None,
                    "max_epoch": max_v,
                    "max_utc": dt.datetime.fromtimestamp(max_v, tz=dt.timezone.utc).isoformat() if max_v is not None else None,
                    "num_rows": row_group.get(3),
                }
            )
    return hits


def iter_parquet(paths: Iterable[Path]) -> Iterable[Path]:
    for path in paths:
        if path.is_dir():
            yield from path.rglob("*.parquet")
        elif path.suffix == ".parquet":
            yield path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--min-epoch", type=int, default=1_500_000_000)
    parser.add_argument("--max-epoch", type=int, default=2_100_000_000)
    parser.add_argument("--limit", type=int, default=0, help="Stop after N matching files/hits; 0 means no limit")
    args = parser.parse_args()

    count = 0
    for path in iter_parquet(args.paths):
        try:
            hits = scan_file(path, args.min_epoch, args.max_epoch)
        except Exception as exc:  # keep batch scans moving
            print(json.dumps({"file": str(path), "error": str(exc)}))
            continue
        for hit in hits:
            print(json.dumps(hit, sort_keys=True))
            count += 1
            if args.limit and count >= args.limit:
                return


if __name__ == "__main__":
    main()
