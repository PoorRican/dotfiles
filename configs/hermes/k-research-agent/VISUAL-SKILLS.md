# KRA visual explanation skills

The public allowlist in `skills.nix` includes these complementary capabilities:

| Skill | Role |
|---|---|
| `concept-diagrams` | Static, minimal educational SVG figures as HTML |
| `manim-video` | Mathematical/geometric animation and progressive explanation |
| `p5js` | Interactive browser exploration and step-by-step visualization |
| `excalidraw` | Editable storyboards, concept maps, and diagrams |
| `archify` | Validated, explorable architecture, workflow, sequence, dataflow, and lifecycle diagrams |

`architecture-diagram` remains available for software/infrastructure diagrams.
It is not the default choice for educational scientific figures.

## Catalog provenance

The complete bundles are distributed by the existing Nix skill catalog;
there is no new runtime installer or broad change to other agents' collections.

- `manim-video`, `p5js`, and `excalidraw` use the existing catalog bundles.
- `concept-diagrams` is a byte-exact import of the installed Hermes optional
  bundle from Hermes revision `aa30e02d860fb2683db0d9d2241d4980a6ee6978`.
- `archify` is a byte-exact import of the full `archify/` directory from
  `https://github.com/tt-a1i/archify`, revision
  `58ab0b98d2d0def8e49dced705c7b566936723ec`, package version `3.0.1`.
  It includes the Node CLI, renderers, validators, schemas, references, examples,
  tests, and license notices—not Hermes' catalog stub.

Retain imported bytes and notices when updating these vendor bundles. Their
upstream whitespace is preserved rather than silently reformatted.

## Runtime use

Start a new KRA conversation to include the new skills in its prompt index.
Existing conversations can explicitly load a named skill with `skill_view`;
skill roots are refreshed from the live configuration by file identity.

To preload the visual toolkit in a CLI conversation:

```sh
k-research-agent --skills concept-diagrams,manim-video,p5js,excalidraw,archify
```

Manim is available through an isolated uv environment; no pip installation into
Hermes' sealed Nix interpreter is needed:

```sh
uv run --python 3.12 --with 'manim==0.22.0' manim -ql script.py SceneName
```

A render smoke test exercised Pango text, a LaTeX equation, animation, and MP4
output. The host supplies Cairo/Pango development libraries, LaTeX, dvisvgm,
and FFmpeg. Those are host prerequisites, not dependencies bundled by the skill.

Load `archify` and use the absolute `bin/archify.mjs` path beneath its returned
`skill_dir`. Its runtime needs Node; browser checks use the installed Chromium.
Do not run `npm install` in the immutable skill bundle.

## Scoped deployment

The initial skill-only activation was deliberately not a full Home Manager
switch, because this checkout also contains unrelated pending changes.
The Nix-rendered target configuration changed only `skills.external_dirs`:
existing bundles and onboarding acknowledgements were preserved, other profiles
were not activated, and the gateway was not restarted.

A GC-rooted configuration, the preceding configuration backup, and an activation
receipt are retained under:

`~/.local/state/hermes/scoped-deployments/k-research-agent/visual-skills/`

The normal reviewed `home-manager switch --flake .#cbox` subsequently distributes
the same allowlisted skills from source. It also applies the rest of the reviewed
configuration, so do not use it merely to refresh these skills while unrelated
changes must remain undeployed.

## Primer quality

Choose the medium to suit the teaching objective. Start with the misconception
or question, follow a concrete example through transformations, show tensor
shapes where they change, and reveal connections progressively. Automated
validation and browser checks establish artifact behavior, not pedagogical or
perceptual quality; inspect the actual figures and frames before claiming those.
