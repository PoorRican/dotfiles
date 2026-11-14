# Interactive vs structural skill split

Scope: when a skill is half conversational workflow (an interview, review loop, or orchestration) and half the contract for a durable artifact, split it into a paired interactive skill and structural skill so each half can be used alone.

## The split

- The interactive skill keeps the trigger phrases, the question flow, the challenge protocol, delegation and sub-agent timing, and instructions for incremental editing during the interaction.
- The structural skill keeps the artifact contract: sections, tag and confidence semantics, update and append-only rules, a validation checklist, common pitfalls in the artifact itself, and `references/template.md` as the canonical scaffold.
- Agents that already hold the content can then write and validate the artifact from the structural skill without loading interview logic; agents running the workflow do not wade through section rules.

## Packaging

- Name the pair for the artifact class, not for a project or session (for example `research-proposal-interview` with `research-proposal-structure`, or `experiment-log-interview` with `experiment-log-structure`).
- Link both ways in `metadata.hermes.related_skills`, put a short pointer to the structural companion near the top of the interactive skill, and keep the template in the structural skill's `references/template.md`, not buried in prose.
- Verify the split by checking that an agent could produce the standardized artifact from the structural skill alone, and could run the workflow without the structural prose for every rule.

## When not to split

- A purely operational skill that produces no durable artifact, a one-off artifact not worth standardizing, or a case where splitting adds overhead with no reuse.
- Keep the full artifact contract in one home; minor overlap is fine, duplicated rules are not. Prefer a few class-level skills to one narrow skill per artifact instance.
