import json
import re
from pathlib import Path
import sys


def main() -> None:
    payload = json.loads(sys.stdin.read())
    local_root = Path(payload["local_root"])
    markdown_paths = payload.get("data_sources", {}).get("markdown", [])
    if not markdown_paths:
        raise ValueError("no markdown data source configured")

    target = local_root / markdown_paths[0]
    text = target.read_text(encoding="utf-8")

    entries = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("-"):
            continue
        amount_match = re.search(r"\$([0-9]+(?:\.[0-9]{1,2})?)", line)
        due_match = re.search(r"due\s+([0-9]{4}-[0-9]{2}-[0-9]{2})", line)
        if amount_match and due_match:
            entries.append(
                {
                    "amount": float(amount_match.group(1)),
                    "due": due_match.group(1),
                }
            )

    entries.sort(key=lambda item: item["due"])
    total_due = round(sum(item["amount"] for item in entries), 2)
    next_due_date = entries[0]["due"] if entries else None
    next_due_amount = entries[0]["amount"] if entries else 0.0

    print(
        json.dumps(
            {
                "bill_count": len(entries),
                "total_due": total_due,
                "next_due_date": next_due_date,
                "next_due_amount": next_due_amount,
            }
        )
    )


if __name__ == "__main__":
    main()
