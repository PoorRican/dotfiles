---
name: media-transfer-to-te-amo
description: Use when copying TV media onto /mnt/Te_Amo and the imported show must be reshaped to match the nested TV Shows library layout on Te_Amo.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [media, exfat, rsync, tv-library, te-amo]
    related_skills: [arch-exfat-write-permissions]
---

# Transfer TV media to Te_Amo

## Overview

This workflow is for moving TV content from another mounted drive into the organized TV library on `Te_Amo`. On this machine, `Te_Amo` is an exFAT drive mounted at `/mnt/Te_Amo`, and the canonical TV library layout lives under `/mnt/Te_Amo/TV Shows`, not `/mnt/Te_Amo/TV`.

The important pattern learned here: do not infer the canonical library shape from stray files in `/mnt/Te_Amo/TV`. First inspect the exact example the user points to inside `/mnt/Te_Amo/TV Shows`. For this host, `Peaky Blinders` under `/mnt/Te_Amo/TV Shows/Peaky Blinders` is the correct model: one show folder containing `Season NN` subfolders, with episode files inside each season folder. `The Mandalorian` therefore belongs in `/mnt/Te_Amo/TV Shows/The Mandalorian/Season 01/` and `/Season 02/`, not flattened into `/mnt/Te_Amo/TV`.

## When to Use

- User wants media copied from another mounted drive into `/mnt/Te_Amo`
- The source is a TV show with `Season N` folders
- The user says to match the layout of other TV shows already on `Te_Amo`
- The destination should land in `/mnt/Te_Amo/TV Shows/<Show>/Season NN/`
- The source/destination are exFAT mounts under `/mnt`

Do not use for:
- Movie imports into a movie-specific hierarchy
- Bulk library reorganization without first checking how the destination is already organized
- Cases where the user explicitly wants to preserve the source folder structure
- Any case where you have not yet inspected the canonical example under `/mnt/Te_Amo/TV Shows`

## Steps

1. Confirm mounts and writable access.
   - Check `/mnt` mounts and the exact source label/path.
   - If the source drive is not mounted, mount it first.
   - Verify both source and destination are writable.

2. Check available space on `Te_Amo` before copying.
   - Use `df -h /mnt/Te_Amo`
   - Optionally size the source with `du -sh /path/to/show`

3. Inspect the destination library structure before deciding the target shape.
   - Look for an existing comparable show in `/mnt/Te_Amo/TV Shows`
   - If the user names an example (for example `Peaky Blinders`), inspect that exact example first
   - Confirm whether the canonical destination is the organized library under `/mnt/Te_Amo/TV Shows` rather than loose files in `/mnt/Te_Amo/TV`
   - Determine the required nesting:
     - `/mnt/Te_Amo/TV Shows/<Show>/Season NN/`
   - Determine the expected episode naming convention inside each season folder

4. Copy first, then normalize layout.
   - Use `rsync -avh --info=progress2` for the copy so progress and retries are manageable.
   - Copy into the organized TV library, not the loose `/mnt/Te_Amo/TV` staging area.
   - Example copy of a show folder:
     - source: `/mnt/SOURCE/TV/The Show/`
     - dest: `/mnt/Te_Amo/TV Shows/The Show/`

5. If the source naming does not match the organized TV Shows layout, normalize the imported show.
   - Ensure the show lives at `/mnt/Te_Amo/TV Shows/<Show>/`
   - Ensure season folders are zero-padded: `Season 01`, `Season 02`, ...
   - Rename episodes to match neighboring organized shows if needed
   - Example transform inside a season folder:
     - `The Mandalorian S01E01.mp4` -> `The Mandalorian - S01E01.mp4`
   - Delete transient torrent residue like `~uTorrentPartFile_*.dat`
   - Remove accidental staging copies or wrongly flattened files from `/mnt/Te_Amo/TV` after successful verification

6. Verify final state.
   - Confirm expected episode count
   - Confirm the show now lives under `/mnt/Te_Amo/TV Shows/<Show>/Season NN/`
   - Confirm there are no mistaken duplicates or flattened leftovers in `/mnt/Te_Amo/TV`
   - Confirm total size on destination roughly matches the source
   - Re-check free space if useful to the user

## Useful command patterns

Check space:
```bash
df -h /mnt/Te_Amo
du -sh "/mnt/SOURCE/TV/The Show"
```

Copy with progress:
```bash
rsync -avh --info=progress2 "/mnt/SOURCE/TV/The Show/" "/mnt/Te_Amo/TV/The Show/"
```

Inspect destination example layout:
```bash
find '/mnt/Te_Amo/TV Shows/Peaky Blinders' -maxdepth 2 -printf '%y %P\n' | sort
```

Normalize into `TV Shows/<Show>/Season NN/` with show-style filenames:
```python
from pathlib import Path
import shutil, re
src_root = Path('/mnt/Te_Amo/TV')
dst_root = Path('/mnt/Te_Amo/TV Shows/The Mandalorian')
for season in ('01', '02'):
    (dst_root / f'Season {season}').mkdir(parents=True, exist_ok=True)
pat = re.compile(r'^The\.Mandalorian\.S(\d{2})E(\d{2})\.mp4$')
for f in sorted(src_root.glob('The.Mandalorian.S??E??.mp4')):
    m = pat.match(f.name)
    if not m:
        continue
    season, episode = m.groups()
    dst = dst_root / f'Season {season}' / f'The Mandalorian - S{season}E{episode}.mp4'
    shutil.move(str(f), str(dst))
```

Verify organized result:
```bash
find '/mnt/Te_Amo/TV Shows/The Mandalorian' -maxdepth 2 -printf '%y %P\n' | sort
find '/mnt/Te_Amo/TV Shows/The Mandalorian' -type f -name '*.mp4' | wc -l
```

## Common Pitfalls

1. Mistaking loose files in `/mnt/Te_Amo/TV` for the canonical TV library.
   - The organized library for shows is `/mnt/Te_Amo/TV Shows`. Inspect the user-named example there first.

2. Assuming the source structure should be preserved exactly.
   - Preserve the show/season hierarchy, but normalize names to the established `TV Shows/<Show>/Season NN/` pattern if needed.

3. Forgetting torrent residue files.
   - Imported season folders may contain `~uTorrentPartFile_*.dat`; remove them during cleanup.

4. Checking only for the show folder and not the actual file naming convention.
   - The important compatibility clues are both nesting and filename style, e.g. `Peaky Blinders - S05E01.mp4` inside `Season 05`.

5. Using a slow recursive search of the whole source drive when the user already identified the content type.
   - If they mention TV shows, check `/mnt/<drive>/TV` directly instead of broad whole-disk searches.

6. Declaring success before verifying counts and cleanup.
   - Confirm the intended number of episodes exists in `/mnt/Te_Amo/TV Shows/<Show>/Season NN/` and that accidental staging files in `/mnt/Te_Amo/TV` are gone.

## Verification Checklist

- [ ] Source drive mounted under `/mnt`
- [ ] `Te_Amo` has enough free space
- [ ] Canonical layout inspected using the exact comparison show under `/mnt/Te_Amo/TV Shows`
- [ ] Copy completed successfully
- [ ] Final file placement matches `/mnt/Te_Amo/TV Shows/<Show>/Season NN/`
- [ ] Episode naming matches neighboring organized shows
- [ ] Torrent part files removed if present
- [ ] Mistaken staging files in `/mnt/Te_Amo/TV` removed if they were created
- [ ] Episode count and total size verified
