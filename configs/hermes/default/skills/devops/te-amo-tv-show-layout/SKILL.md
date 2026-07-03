---
name: te-amo-tv-show-layout
description: Canonical folder and filename shape for TV shows stored under /mnt/Te_Amo/TV Shows.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [media, tv-library, te-amo, naming, layout]
    related_skills: [media-transfer-to-te-amo]
---

# Te_Amo TV show layout

## Purpose

Use this skill whenever adding, moving, renaming, or validating episodic TV content inside `/mnt/Te_Amo/TV Shows`.

## Canonical shape

TV shows belong under:
- `/mnt/Te_Amo/TV Shows/<Show Name>/`

Each season belongs under the show folder as a zero-padded season directory:
- `/mnt/Te_Amo/TV Shows/<Show Name>/Season 01/`
- `/mnt/Te_Amo/TV Shows/<Show Name>/Season 02/`
- etc.

Episode files belong inside the corresponding season directory and should include the show name plus season/episode code:
- `/mnt/Te_Amo/TV Shows/Peaky Blinders/Season 05/Peaky Blinders - S05E01.mp4`
- `/mnt/Te_Amo/TV Shows/The Mandalorian/Season 02/The Mandalorian - S02E08.mp4`

## Naming rules

1. Use `/mnt/Te_Amo/TV Shows`, not `/mnt/Te_Amo/TV`, for the organized TV-show library.
2. Use one top-level folder per show.
3. Use zero-padded season folders: `Season 01`, `Season 02`, not `Season 1`, `Season 2`.
4. Put episodes inside the matching season folder.
5. Prefer filenames in the form:
   - `<Show Name> - SxxExx.<ext>`
6. Keep subtitle files and related season-specific assets in the same season folder when they belong to a specific episode.
7. Remove transient torrent residue such as `~uTorrentPartFile_*.dat`.
8. Do not leave accidental flattened copies of episode files in `/mnt/Te_Amo/TV` when the canonical library copy is under `TV Shows`.

## Example

Good:
- `/mnt/Te_Amo/TV Shows/The Mandalorian/Season 01/The Mandalorian - S01E01.mp4`
- `/mnt/Te_Amo/TV Shows/The Mandalorian/Season 02/The Mandalorian - S02E01.mp4`

Bad:
- `/mnt/Te_Amo/TV/The.Mandalorian.S01E01.mp4`
- `/mnt/Te_Amo/TV Shows/The Mandalorian/Season 1/The Mandalorian S01E01.mp4`

## Verification

Check a show's structure:
```bash
find '/mnt/Te_Amo/TV Shows/<Show Name>' -maxdepth 2 -printf '%y %P\n' | sort
```

Count episodes:
```bash
find '/mnt/Te_Amo/TV Shows/<Show Name>' -type f -name '*S??E??*' | wc -l
```

Check for mistaken flattened leftovers:
```bash
find /mnt/Te_Amo/TV -maxdepth 1 -type f -iname '*<show-name-fragment>*'
```

## Pitfalls

- Do not infer the canonical shape from stray files in `/mnt/Te_Amo/TV`.
- Always inspect the exact comparison show the user names.
- Some shows may contain extras or subtitles; keep them with the show and season they belong to unless the user asks otherwise.
