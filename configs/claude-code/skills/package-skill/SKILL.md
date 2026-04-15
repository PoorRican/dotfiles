---
name: package-skill
description: Package a Claude Code skill directory into a distributable .skill file. Use when the user wants to export, package, bundle, zip, or distribute a skill. Triggers on mentions of .skill files, packaging skills, exporting skills, or sharing skills.
allowed-tools: Read, Glob, Grep, Bash(zip *), Bash(unzip *), Bash(ls *), Bash(find *), Bash(file *), Bash(mkdir *), Bash(cat *), Bash(wc *)
---

# Package Skill (.skill)

Package a Claude Code skill directory into a distributable `.skill` file.

## What is a .skill file?

A `.skill` file is a zip archive containing a complete skill directory. It preserves the directory structure so the recipient can install it by unzipping into their skills location.

```
my-skill.skill (zip archive)
└── my-skill/
    ├── SKILL.md          # Required
    ├── reference/         # Optional nested docs
    │   └── *.md
    └── *.sh / *.py       # Optional scripts
```

## Packaging Workflow

1. **Identify the skill to package.** Ask the user which skill directory to package. Check both locations:
   - Project skills: `.claude/skills/*/SKILL.md`
   - Personal skills: `~/.claude/skills/*/SKILL.md`

2. **Validate the skill directory.** Before packaging, verify:
   - `SKILL.md` exists and has valid YAML frontmatter (`name:` and `description:` fields)
   - All files referenced in SKILL.md (e.g., `reference/*.md`, scripts) actually exist
   - No absolute paths leak into the SKILL.md content (all references should be relative like `reference/guide.md`)
   - No secrets, API keys, `.env` files, or credentials are included
   - Shell scripts have executable permissions (`chmod +x`)

3. **Run pre-package checks.** Report to the user:
   - Skill name (from frontmatter)
   - File count and total size
   - List of all files that will be included
   - Any warnings (absolute paths, missing references, large files > 100KB)

4. **Create the .skill file.** Package the skill:
   ```bash
   cd <parent-of-skill-dir> && zip -r <output-path>/<skill-name>.skill <skill-dir-name>/
   ```
   The zip must contain the skill directory as the top-level entry (not loose files).

5. **Verify the package.** After creating:
   ```bash
   unzip -l <skill-name>.skill
   ```
   Confirm the structure looks correct.

6. **Report the result.** Tell the user:
   - Output file path and size
   - How to install: `unzip <name>.skill -d ~/.claude/skills/`
   - How to install project-wide: `unzip <name>.skill -d .claude/skills/`

## Validation Rules

### SKILL.md Frontmatter

The SKILL.md must have valid frontmatter with at least:
```yaml
---
name: skill-name
description: When to use this skill...
---
```

Optional frontmatter fields:
- `allowed-tools:` — restricts which tools the skill can use

### Relative References

All file references in SKILL.md must be relative to the skill directory. Flag these patterns as errors:
- Absolute paths: `/Users/...`, `/home/...`, `~/...`
- Project-relative paths: `.claude/skills/skill-name/reference/...`
- Source tree paths: `configs/...`, `src/...`

Correct pattern: `reference/guide.md`, `create_profile.sh`

### Excluded Files

Do not include in the package:
- `.DS_Store` files
- `__pycache__/` directories
- `.env` or credentials files
- `.git/` directories
- Files larger than 1MB (warn and ask user)

Use zip exclusion flags:
```bash
zip -r <output>.skill <dir>/ -x "*.DS_Store" -x "*__pycache__/*" -x "*.env" -x "*/.git/*"
```

## Installing a .skill File

To install a `.skill` file:
```bash
# Personal (available in all projects):
unzip skill-name.skill -d ~/.claude/skills/

# Project-specific:
unzip skill-name.skill -d .claude/skills/
```

The skill is available immediately — no restart needed.

## Output Location

Place the `.skill` file in the current working directory unless the user specifies otherwise.
