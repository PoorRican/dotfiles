# Neovim Helix Motion Trial Design

## Objective

Evaluate `chtenb/helix.vim` as a basis for selection-first editing in Neovim, with behavior measured against Helix 25.07.1 rather than inferred from Vim mappings.

The trial prioritizes:

- motion-first, `selection -> action` editing;
- Normal-mode motions that replace the active selection;
- Select-mode motions that extend the active selection;
- regex selection and matching/text-object commands;
- single-selection behavior.

Multiple selections and generic Tree-sitter/LSP integration are desirable but do not block the trial.

## Baselines

Pin the implementations used as behavioral references:

- Helix 25.07.1: `a05c151bb6e8e9c65ec390b0ae2afe7a5efd619b`
- `chtenb/helix.vim`: `958314b6210d93d1abd4b1bc23b06a69fd17e3e9`

The Helix keymap, tutor, and upstream integration tests at the pinned Helix revision define expected behavior. Existing Vim behavior does not override that oracle.

## Trial isolation

The first trial runs in a temporary Neovim environment and must not modify the main Neovim configuration, lazy.nvim state, or plugin lockfile.

The launcher will:

1. create temporary config, data, state, and cache directories;
2. install or expose the pinned `helix.vim` revision there;
3. start `nvim --clean` with only the compiled upstream mapping file;
4. open a pinned copy of the Helix tutor on request;
5. remove the temporary environment cleanly.

A second integration trial may load the current configuration plus `helix.vim` only after the isolated baseline is measured.

## Conformance harness

A headless Neovim runner will execute declarative fixtures containing:

- initial buffer text;
- initial selection anchor and head;
- input key sequence;
- expected buffer text;
- expected selection anchor and head;
- expected editor mode.

Fixtures will use Helix's selection-marker notation where practical:

- `#[foo|]#`: forward primary selection;
- `#[|foo]#`: reverse primary selection;
- `#(foo|)#`: secondary selection, skipped while multiple selections are out of scope.

For each fixture the runner will create a scratch buffer, establish the initial selection, feed keys, wait for pending mappings, capture the resulting state, and classify the result as pass, fail, unsupported, or intentional divergence. Failures must remain visible; expected-failure annotations require an explicit reason.

## Test corpus

### Tutor-derived acceptance cases

Convert relevant tutor exercises into deterministic fixtures, concentrating on:

- word and WORD motions;
- counts and selection direction;
- Normal versus Select mode;
- collapse and flip selection;
- search and search-from-selection;
- regex selection;
- `f`, `F`, `t`, and `T`, including cross-line movement;
- delimiter matching, inside/around objects, and surrounds;
- selection-first delete, change, yank, insert, and append.

The tutor remains available for a manual end-to-end session. Its prose cannot itself be executed because many exercises permit multiple valid key sequences.

### Upstream Helix fixtures

Curate single-selection cases from Helix's Rust integration tests. Preserve each fixture's upstream test name, source path, and pinned revision. These fixtures provide exact expectations for selection endpoints, direction, boundaries, counts, matching, and edits.

Do not attempt to import every Rust test initially. Multiselection, language-server, syntax-tree, picker, and terminal-UI cases may be added separately.

## Failure handling

Classify failures before changing behavior:

1. upstream `helix.vim` passes;
2. Neovim-specific compatibility defect;
3. known `helix.vim` placeholder or limitation;
4. out of trial scope;
5. intentional divergence approved for this configuration.

Patch only categories 2 and 3 during the experiment. Keep adaptations in a thin overlay so the upstream baseline remains independently runnable and comparable.

## Integration trial

After the clean baseline, run the same suite against a temporary profile that loads the current Neovim configuration and then activates the Helix layer after lazy startup.

Add smoke coverage for editable LSP/Tree-sitter buffers and for buffer-local interfaces such as Telescope/FZF, Neo-tree, Trouble, Git panes, terminals, opencode, and Agentic. Helix behavior should apply only to ordinary editable buffers unless an adapter explicitly supports another buffer type.

The integration report must identify mappings changed after lazy or buffer-local plugin initialization.

## Success criteria

The experiment succeeds when:

- `w`, `e`, `b` and uppercase variants match Helix around punctuation, whitespace, newlines, and file boundaries;
- counts construct the expected selection;
- Normal motions replace selections and Select-mode motions extend them;
- `d`, `c`, `y`, `i`, and `a` operate on the visible selection;
- practical tutor regex-selection cases work;
- common delimiter matching and inside/around selections work;
- `f`, `F`, `t`, and `T` work across lines;
- failures are reproducible headlessly with useful diagnostics;
- clean and integrated results can be compared;
- the trial can be removed without changing normal Neovim state.

Subjective acceptance additionally requires completing the relevant tutor exercises in the isolated interactive profile.

## Non-goals

The initial trial does not require:

- exact multiple-selection support;
- complete Tree-sitter or LSP parity;
- immediate migration of existing keybindings;
- modification of the main Neovim startup path;
- preserving Vim operator-first muscle memory.

## Decision point

After baseline and integration reports, choose among:

1. adopt upstream plus a small compatibility overlay;
2. maintain a Neovim-specific fork if important failures require structural changes;
3. reject `helix.vim` and use the conformance corpus to build a native selection-first layer.
