---
name: media-transfer-to-te-amo
description: Use when transferring, organizing or validating episodic TV media in a mounted library, including show and season naming.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [media, exfat, rsync, tv-library, naming]
    related_skills: [arch-exfat-write-permissions]
---

# TV media transfer and layout

The organized TV library uses `<mount>/TV Shows/<Show>/Season NN/<Show> - SxxExx.<ext>`, with zero-padded season numbers. Loose files under `<mount>/TV` are not a reliable example of the library layout. Keep episode subtitles and season-specific extras with their season.

1. Confirm the intended mount, source readability, destination writability and available space before copying. A read-only source is sufficient; compare `du -sh "<source-show>"` with `df -h "<mount>"`.
2. If the user names a comparison show, inspect it when available with `find "<mount>/TV Shows/<comparison-show>" -maxdepth 2 -printf '%y %P\n' | sort`; otherwise use the stated convention or the user's requested layout. Preserve source structure if requested.
3. Copy into the organized show directory, not the loose `TV` directory: `rsync -avh --ignore-existing --info=progress2 "<source-show>/" "<mount>/TV Shows/<Show>/"`. This skips every existing destination file, including a truncated file from an interrupted copy. Inspect skipped files individually against the source by size or checksum and resolve conflicts before declaring success. Normalize imported season and episode names as needed, without overwriting existing files.
4. Verify the copied video files and expected episode count against the source; subtitles are not episodes. Compare total size and check for unintended flattened copies separately.
5. Do not delete torrent residue, source files or staging copies without establishing they are no longer needed and obtaining authorization.
