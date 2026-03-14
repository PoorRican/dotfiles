---
name: "obsidian-cli"
version: "1.0.0"
description: "Instructions for using the Obsidian CLI in a vault workflow."
metadata:
  nuro:
    install:
      - manager: "yay"
        package: "obsidian-bin"
  openclaw:
    requires:
      bins: ["obsidian"]
---
# Obsidian CLI

Use this skill when you need to operate on an Obsidian vault from the command line.

## Usage Guidelines

1. Confirm the vault path before running commands.
2. Prefer read/list actions before write/move actions.
3. Keep filenames stable and preserve existing wiki-link targets.
4. When adding content, follow the vault's existing heading and frontmatter style.
5. After write operations, verify links still resolve.

## Command Patterns

- Inspect CLI help:
  `obsidian --help`
- Open a note in Obsidian:
  `obsidian "Vault Name" "Folder/Note.md"`
- Open a vault:
  `obsidian "Vault Name"`

## Safety

- Do not move or rename notes unless the task explicitly requires it.
- Do not delete notes without an explicit instruction.
- Keep edits scoped to the requested directory and task.
