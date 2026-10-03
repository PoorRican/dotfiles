# Skill tooling

Scope: Durable packaging facts and one quality check for externally discovered skills.

## Skill archive contents

- A distributable `.skill` archive preserves the skill directory as its top-level entry rather than placing its files loose at archive root. (src: package-skill; 2026-04-15)
- Packaging validation includes resolvable relative references and excludes credentials, `.env`, `.git`, cache files, and oversized artifacts. (src: package-skill; 2026-04-15)

## Skill discovery

- Search ranking or install counts alone are weak evidence for recommending a skill; source review and evidence of adoption provide a stronger basis. (src: find-skills; 2026-06-18)
