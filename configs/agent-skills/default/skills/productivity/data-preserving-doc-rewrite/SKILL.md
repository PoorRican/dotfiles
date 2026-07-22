---
name: data-preserving-doc-rewrite
description: "Use when rewriting a large machine-assembled document (compendium, report, data dump) into better prose/tables WITHOUT changing any numbers, IDs, dates, or empirical claims — especially when parallelizing across sections with subagents and needing to prove zero data loss."
---

## Goal

Rewrite a large doc (prose style, fenced dumps → real markdown tables) while guaranteeing zero alteration of numbers, IDs, dates, or claims. The proof is programmatic multiset conservation, not eyeballing.

## Workflow

1. **Snapshot first.** `cp doc.md /tmp/doc-orig.md` before any edit. Every diff is measured against this.
2. **Split on structural separators for parallel work.** If the doc has section separators (e.g. bare `---` horizontal rules), split on `\n---\n` into disjoint per-section files. Disjoint files = subagents never edit the same file, so no concurrent-edit clobbering. Reassemble with `sep.join(seg.strip() for seg in segments)` + trailing newline.
3. **One subagent per section, single parallel batch.** Put the style contract + inviolable constraints + table-conversion legend in the shared `context`; give each task its section's inventory + input/output paths. Instruct each to read its source file FIRST (never reconstruct cells from the plan/transcript — planning reads are often truncated) and to self-verify token conservation before reporting. Have YOU (not the plan) own the top-level decomposition; the plan's row-count estimates are hints, the source file is truth — keep every actual row.
4. **Assemble, then verify globally** (below). The subagent self-checks are a nice-to-have; your global check after assembly is the binding gate.

## Verification harness (Python, against the snapshot)

```python
import re
from collections import Counter
NUM = re.compile(r'-?\d[\d,]*\.?\d*(?:e[+-]?\d+)?')
def numc(t): return Counter(m.replace(',', '') for m in NUM.findall(t))
def idc(t):  return Counter(m.rstrip('.,;:|)`') for m in re.findall(r'ID_PATTERN\S*', t))
```

- **Numeric-token conservation:** `Counter(orig) - Counter(new)` and reverse. Removed tokens must ALL trace to whitelisted dedups, header-label consolidation (a repeated `p25/p50/...` header printed once), or tokenization artifacts of a mandated sentence (collapsing `2026-06-01, 06-02` drops one `2026`). Anything else is a bug.
- **Positively confirm data VALUES survive** — do NOT trust the net counter alone. Comma-normalization (`92542`→`92,542`) shifts raw string counts; grep the specific critical values and assert `new_count >= 1`.
- **ID conservation:** domain-ID multiset (e.g. `KXMLB\S+`) must be exactly equal both ways.
- **Headings verbatim:** `[l for l in text if l.startswith('#')]` identical in order+text — preserves TOC anchors and `§N.M` cross-refs with zero link maintenance. Watch for subagents flattening smart quotes (`“”`→`""`) in headings; restore them.
- **Adding intro prose?** Spell numbers as words ("fifteen", not "15") so the numeric-token multiset stays exact.

## Markdown-render gotchas (both confirmed empirically)

- **GFM needs a blank line before every table**, or the header row is absorbed into the preceding paragraph and the table renders as literal `|` text. After rewriting, insert a blank line before any table row whose preceding line is non-blank and non-pipe.
- **Escape-aware pipe counting for table lint:** cells may contain literal `\|` (e.g. `|Δmid|` written `\|Δmid\|`). Count structural pipes with `re.findall(r'(?<!\\)\|', line)`, not `line.count('|')`, or you get false "inconsistent pipe count" violations. Lint = per block: constant unescaped-pipe count + row 2 is a `---`/`:--` separator.
- Consider rewriting a header token containing a bare `|` (e.g. `mean |Δ|` → `mean abs(Δ)`) rather than escaping, to keep tables unambiguous.

## Final gate before commit

Zero fenced quasi-tables remain, 0 table-lint violations, headings byte-identical, all TOC anchors resolve, style-ban greps (dramatic labels, `therefore`/`however`, etc.) return zero, and one independent coherence read-back (a read-only scout comparing high-risk transposes/splits against the snapshot) passes. Commit with a `docs:` conventional-commit; code test/lint suites are unaffected by a docs-only change.
