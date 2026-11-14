---
name: agent-skill-library-governance
description: Audit, deduplicate, or migrate agent skill libraries. Use when multiple roots, deployment aliases, or overlapping skills make ownership and canonical bundles unclear.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [skills, governance, migration, deduplication, provenance, multi-agent]
    related_skills: [hermes-agent-skill-authoring, coding-agent-output-styles, hermes-agent]
---

# Agent Skill Library Governance

Skill-library governance identifies maintained sources and reconciles duplicate or overlapping bundles before migration. The unit of migration is the **whole skill bundle**: `SKILL.md` plus references, scripts, templates, assets, executable bits, and intentional symlinks. A matching `SKILL.md` alone does not prove two bundles are identical.

## Reference

| When | Reference |
|---|---|
| Inventory, compare, map, or migrate skill bundles | [Governance workflow](references/cross-agent-source-classification.md) |
