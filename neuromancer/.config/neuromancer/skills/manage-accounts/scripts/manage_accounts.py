import csv
import json
from pathlib import Path
import sys


def main() -> None:
    payload = json.loads(sys.stdin.read())
    local_root = Path(payload["local_root"])
    csv_paths = payload.get("data_sources", {}).get("csv", [])
    if not csv_paths:
        raise ValueError("no csv data source configured")

    target = local_root / csv_paths[0]
    total_balance = 0.0
    account_count = 0

    with target.open("r", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            account_count += 1
            total_balance += float(row.get("balance", "0") or "0")

    print(
        json.dumps(
            {
                "account_count": account_count,
                "total_balance": round(total_balance, 2),
            }
        )
    )


if __name__ == "__main__":
    main()
