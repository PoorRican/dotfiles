# AUR compromise check example — June 2026 malicious adoptions

Use this as a concrete reference for future AUR supply-chain incident checks. Do **not** treat the package names or payload strings here as timeless; they are incident-specific indicators.

## Authoritative sources used

- Arch news: `https://archlinux.org/news/active-aur-malicious-packages-incident/`
- AUR report thread: `https://lists.archlinux.org/archives/list/aur-general@lists.archlinux.org/thread/FGXPCB3ZVCJIV7FX323SBAX2JHYB7ZS4/`
- Maintainer-linked affected list from the report thread: `https://md.archlinux.org/s/SxbqukK6IA/download`

The Arch-linked list stated it contained many, but not all, affected packages. Preserve that caveat in user-facing results.

## Workflow

1. Fetch the raw affected list from the HedgeDoc `/download` URL.
2. Parse one package name per line.
3. Compare against:
   - `pacman -Qm` for current foreign/AUR-style packages.
   - `pacman -Qq` for all current packages.
4. Scan package metadata and helper caches for known incident indicators:
   - `atomic-lockfile`
   - `js-digest`
   - `npm install`
   - `bun add`
5. Parse `/var/log/pacman.log` for historical package actions involving affected names.
6. Summarize as “no known affected package found” rather than “system guaranteed clean” if the source list is incomplete.

## Reusable script shape

```python
import re, urllib.request
from pathlib import Path

AFFECTED_URL = "https://md.archlinux.org/s/SxbqukK6IA/download"
text = urllib.request.urlopen(
    urllib.request.Request(AFFECTED_URL, headers={"User-Agent": "Mozilla/5.0"}),
    timeout=30,
).read().decode("utf-8", "replace")

affected = {
    line.strip()
    for line in text.splitlines()
    if re.fullmatch(r"[A-Za-z0-9@._+\-]+", line.strip())
}
Path("/tmp/aur-affected-packages-2026-06-12.txt").write_text(
    "\n".join(sorted(affected)) + "\n"
)

# Then compare with tool/shell output from:
#   pacman -Qm 2>/dev/null || true
#   pacman -Qq 2>/dev/null || true
# and parse /var/log/pacman.log lines of the form:
#   [timestamp] [ALPM] installed|upgraded|reinstalled|removed <pkg>
```

## Useful local checks

```bash
pacman -Qm 2>/dev/null || true
pacman -Qq 2>/dev/null || true
pacman -Q pacman yay paru npm bun 2>&1 || true

grep -R -E 'atomic-lockfile|js-digest|bun add|npm install' /var/lib/pacman/local ~/.cache/yay 2>/dev/null || true
```

Prefer structured parsing in Python for final comparison so version strings, errors, and log lines do not create false positives.
