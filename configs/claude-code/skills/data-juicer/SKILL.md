---
name: data-juicer
description: Primer for using the data-juicer Python library (also written `datajuicer` or `DJ`) — a YAML-driven, OP-based system for cleaning, filtering, deduplicating, transforming, and synthesizing text and multimodal data for foundation models. Use this skill whenever the user mentions data-juicer, DJ, dj-process, dj-analyze, "DJ format", building data recipes / YAML pipelines for LLM training data, or writing custom Filter / Mapper / Deduplicator / Selector / Aggregator / Grouper operators ("OPs"). Also reach for it when the user is putting together a data preprocessing pipeline for LLM pre-training, post-tuning, or multimodal datasets and DJ would be a natural fit, even if they haven't named the library yet — flagging DJ as an option is often the most helpful move.
---

# Data-Juicer (DJ) Primer

Data-Juicer is a YAML-driven system for cleaning, filtering, deduplicating, transforming, and synthesizing data for foundation models. The main mental model: **a config (YAML "recipe") describes a dataset and a list of operators ("OPs"); an executor streams the dataset through the OPs and writes the result.** OPs are the unit of work — there are 200+ built-in ones, and writing your own is the common case for anything domain-specific.

Almost everything a user will ask about reduces to one of four questions:

1. *What does my recipe look like?* → The config section.
2. *Is there an OP that already does this?* → The OP zoo. **Always check before writing one.**
3. *How do I write a custom OP?* → The custom OP section.
4. *What shape does my data need to be in?* → The DJ format section.

Three reference files sit alongside this one for deeper material:
- `references/op-zoo.md` — the categorical OP listing with descriptions, tags, and per-OP doc links.
- `references/config-reference.md` — the full top-level config schema (every field, not just the common ones).
- `references/custom-ops.md` — deeper patterns: batched processing, GPU acceleration, OP fusion, lazy dependencies.

Load these only when the task actually needs them. For most "how do I get started / what does this look like" questions, this file is enough.

---

## OP categories — the eight top-level types

Every OP inherits from one of these base classes. The class determines its execution contract (what it takes in, what it puts out), so picking the right base class is the first decision when writing a custom OP.

| Type             | Count | What it does                                                                                                                          |
|------------------|------:|---------------------------------------------------------------------------------------------------------------------------------------|
| **Mapper**       |   105 | Edits / transforms a sample. Input = sample, output = sample. The workhorse for cleaning, normalization, augmentation, synthesis.     |
| **Filter**       |    56 | Keeps or drops a sample. Input = sample, output = bool. Two-phase: `compute_stats_single` writes a stat onto the sample, then `process_single` returns the keep/drop decision based on the stat. |
| **Deduplicator** |    10 | Removes duplicates across the dataset (exact, MinHash, SimHash, image/video hashes). Cross-sample, not per-sample.                    |
| **Selector**     |     5 | Picks a subset based on ranking / frequency / range over a field (e.g. top-k, random sample).                                         |
| **Grouper**      |     3 | Groups N samples into one batched sample (input to Aggregators).                                                                      |
| **Aggregator**   |     4 | Reduces a batch of samples into one summary sample (e.g. summarization across docs, entity attribute aggregation).                    |
| **Pipeline**     |     3 | Dataset-level processing — both input and output are full datasets (e.g. Ray + vLLM inference pipelines).                             |
| **Formatter**    |     8 | Discovers, loads, canonicalizes source data into DJ format (csv, json, parquet, tsv, text, HF hub, etc.). Usually invoked implicitly by the dataset config — users rarely instantiate one directly. |

The Filter / Mapper distinction is the one most worth being precise about: Filters never modify samples, they only annotate stats and return a boolean. Mappers freely modify the sample dict (including adding fields). If a custom OP both transforms *and* drops samples, it's two OPs.

For the full categorical listing of OPs, see `references/op-zoo.md`. For the canonical, always-current list, point the user to:
- The **OperatorZoo** page: https://datajuicer.github.io/data-juicer/en/main/docs/Operators.html (rendered, with capability tags and per-OP doc links)
- **`config_all.yaml`**: https://github.com/datajuicer/data-juicer/blob/main/data_juicer/config/config_all.yaml (every OP with every parameter, formatted as YAML — the most concrete reference for what an OP block looks like in a recipe)
- **API reference**: https://datajuicer.github.io/data-juicer/en/main/api.html

---

## The DJ data format

DJ operates on a **non-recursive dict-per-sample** schema, stored on disk as JSONL (preferred), JSON, Parquet, CSV, TSV, TXT, or `jsonl.gz`. Local files have their format auto-detected; remote HuggingFace and arXiv sources are also first-class.

A sample has three logical parts:

```json
{
  // 1. Core payload — directly used by training/fine-tuning downstream.
  "text": "The quick brown fox...",
  "query": "...",       // for post-tuning / dialog datasets
  "response": "...",

  // 2. Extra data — paths to multimodal assets stored on disk as path lists.
  "images": ["path/to/img1.jpg", "path/to/img2.jpg"],
  "audios": ["path/to/audio.wav"],
  "videos": ["path/to/video.mp4"],

  // 3. Meta + stats — either intrinsic to the source, or produced by OPs.
  "meta":  {"src": "customized", "version": "0.1", "author": "..."},
  "stats": {"lang": "en", "text_len": 1234, "image_widths": [224, 336]}
}
```

A few things worth internalizing:

- **`text` is the default payload key.** Most text OPs read from `sample[self.text_key]` where `text_key` defaults to `"text"`. If your data lives under a different field (e.g. `content`, `body`), set `text_keys` at the top level of the config rather than per-OP.
- **`stats` and `meta` are reserved.** Filters write into `sample[Fields.stats][StatsKeys.<name>]`. Don't put your own data there — use top-level fields instead.
- **Multimodal samples interleave special tokens in `text`.** Default tokens: `<__dj__image>`, `<__dj__audio>`, `<__dj__video>`. Tokens correspond positionally to entries in the `images` / `audios` / `videos` arrays. Chunks within a sample are separated by `<|__dj__eoc|>` (end-of-chunk).
- **Format conversion tools** in `tools/fmt_conversion/` convert popular formats (LLaVA, MMC4, WavCaps, Alpaca-CoT, ShareGPT, etc.) to and from DJ format. If a user has data in one of those formats, point them there before suggesting custom conversion: https://github.com/datajuicer/data-juicer/blob/main/tools/fmt_conversion/README.md

---

## Writing a config (the "recipe")

Configs are YAML, parsed by `jsonargparse`. A minimal recipe has three things: where the data is, what to do, and where to put the result.

```yaml
# minimal_recipe.yaml
project_name: 'my-cleanup-pass'
dataset_path: './raw_corpus.jsonl'      # or use a `dataset:` block (see below)
export_path: './cleaned/result.jsonl'   # supports .jsonl / .json / .parquet
np: 8                                   # number of subprocesses

process:
  - whitespace_normalization_mapper:    # mappers transform
  - clean_html_mapper:
  - text_length_filter:                 # filters drop based on stats
      min_len: 50
      max_len: 100000
  - language_id_score_filter:
      lang: 'en'
      min_score: 0.8
  - document_deduplicator:              # dedup is its own category
      lowercase: true
      ignore_non_character: true
```

Run it:

```bash
dj-process --config minimal_recipe.yaml
# or, from source:
python tools/process_data.py --config minimal_recipe.yaml
```

### Key points about the `process` list

- It's an **ordered list** — OPs run top to bottom. Order matters: cheap CPU filters before expensive GPU mappers, dedup near the end after all transforms.
- Each entry is `op_name:` followed by its parameters as a nested dict. An OP with no params still needs the trailing colon (`whitespace_normalization_mapper:`).
- Names are **snake_case registered names**, not Python class names. `TextLengthFilter` → `text_length_filter`. The registered name comes from `@OPERATORS.register_module('name')` in the OP source.
- To find the parameters for any OP, the fastest path is to grep `config_all.yaml` for the OP name — every parameter is shown there with its default and a one-line comment.

### Dataset configuration: the richer `dataset:` block

`dataset_path:` is the legacy shorthand. The modern form is a `dataset:` block, which supports remote sources, mixtures, and validation:

```yaml
dataset:
  max_sample_num: 100000
  configs:
    - type: 'local'
      weight: 0.7
      path: 'path/to/file1.jsonl'
    - type: 'local'
      weight: 0.3
      path: 'path/to/file2.parquet'
    - type: 'remote'
      source: 'huggingface'
      path: 'HuggingFaceFW/fineweb'
      name: 'CC-MAIN-2024-10'
      split: 'train'
      limit: 1000

# Optional: validate before processing
validators:
  - type: 'required_fields'
    required_fields: ['text', 'meta']
    field_types: {text: 'str', meta: 'dict'}
```

For full dataset config syntax (mixture weights, validators, remote sources), see https://datajuicer.github.io/data-juicer/en/main/docs/DatasetCfg.html

### Other top-level fields worth knowing

These are the ones that come up regularly. The full list is in `references/config-reference.md`.

- `text_keys`: which sample fields hold the text payload. Default `'text'`.
- `np`: subprocess count.
- `executor_type`: `'default'` (single-machine HF Datasets) or `'ray'` (distributed).
- `use_cache`: cache OP outputs between runs (default true). Cleared with `dj-process --cleanup_cache`.
- `op_fusion`: enable fusion of OPs that share intermediate variables (e.g. tokenization). Off by default; turn on for noticeable speedup on text-heavy recipes.
- `custom_operator_paths`: list of file paths or directories to register external OPs from. **This is how you use a custom OP without modifying the DJ source tree.**
- `open_tracer` + `op_list_to_trace`: emit before/after samples for specified OPs, useful for debugging recipe behavior.
- For OPs using third-party models, set `mem_required: '<size>GB'` so DJ can throttle parallelism and avoid OOM.

### Overriding from the command line

Anything in the config can be overridden via CLI in dot-notation:

```bash
dj-process --config recipe.yaml --language_id_score_filter.min_score=0.9 --np=16
```

### Helping yourself: `--help` and the analyzer

- `dj-process --help` prints the entire hierarchical config schema (every OP, every parameter, every type). It's verbose but authoritative.
- `dj-analyze --auto --dataset_path my.jsonl [--auto_num 1000]` runs all stat-producing Filters on a sample and emits a report — a good way to size up an unfamiliar dataset before writing a recipe.

---

## Adding custom operators

Two paths exist; pick by where the OP needs to live.

### Path 1: External OP via `custom_operator_paths` (recommended for your own projects)

Write the OP in your own repo, register it via the config. No fork, no PR, no editing DJ's source.

```python
# /my_project/ops/my_filter.py
import sys
from jsonargparse.typing import PositiveInt
from data_juicer.utils.constant import Fields, StatsKeys
from data_juicer.ops.base_op import OPERATORS, Filter


@OPERATORS.register_module('my_text_length_filter')
class MyTextLengthFilter(Filter):
    """Keep samples whose text length is in [min_len, max_len]."""

    def __init__(self, min_len: PositiveInt = 10,
                 max_len: PositiveInt = sys.maxsize,
                 *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.min_len = min_len
        self.max_len = max_len

    def compute_stats_single(self, sample):
        # Filters compute a stat first…
        if 'my_text_len' in sample[Fields.stats]:
            return sample
        sample[Fields.stats]['my_text_len'] = len(sample[self.text_key])
        return sample

    def process_single(self, sample):
        # …then return True (keep) or False (drop) based on the stat.
        return self.min_len <= sample[Fields.stats]['my_text_len'] <= self.max_len
```

Wire it in:

```yaml
custom_operator_paths:
  - '/my_project/ops/my_filter.py'   # single file
  # - '/my_project/ops/'             # or a directory of files

process:
  - my_text_length_filter:
      min_len: 100
      max_len: 50000
```

### Path 2: In-tree OP (for contributing back to DJ)

Same code, but lives at `data_juicer/ops/<category>/<name>.py` and gets exported via the category's `__init__.py`. Required if contributing to upstream; otherwise prefer Path 1 to keep your project decoupled from a DJ fork.

### How OPs work mechanically

Every OP inherits from one of: `Filter`, `Mapper`, `Deduplicator`, `Selector`, `Grouper`, `Aggregator`. The base class dictates the contract:

| Base class       | Methods to implement                                          | Return contract                          |
|------------------|---------------------------------------------------------------|------------------------------------------|
| **Mapper**       | `process_single(sample)`                                      | Modified `sample` dict                   |
| **Filter**       | `compute_stats_single(sample)` + `process_single(sample)`     | Modified `sample` then `bool` (keep)     |
| **Deduplicator** | `compute_hash(sample)` + dataset-level `process(dataset)`     | Hash, then deduped dataset               |
| **Selector**     | `process(dataset)`                                            | Selected subset                          |
| **Grouper**      | `process(dataset)`                                            | Dataset of batched samples               |
| **Aggregator**   | `process_single(batched_sample)`                              | Aggregated output                        |

Always:
- Decorate with `@OPERATORS.register_module('snake_case_name')` — this is what `process:` in the YAML looks for.
- Call `super().__init__(*args, **kwargs)` first.
- Read text via `sample[self.text_key]` (don't hardcode `'text'`).
- For Filters, write stats to `sample[Fields.stats][...]` and check that key first to avoid recomputing if a previous fused OP already produced it.

For batched processing, GPU acceleration, OP fusion (sharing intermediate computations between OPs), and lazy dependency loading, see `references/custom-ops.md`. These matter for performance once an OP is in real use, but are optional for a first pass.

---

## Programmatic API (no YAML)

For interactive work, tests, or embedding in a larger Python pipeline, skip the YAML and call OPs directly:

```python
from data_juicer.core.data import NestedDataset
from data_juicer.ops.filter import TextLengthFilter
from data_juicer.ops.mapper import WhitespaceNormalizationMapper

ds = NestedDataset.from_dict({
    "text": ["Short", "This passes the filter.", "Text with   spaces"]
})

result = ds.process([
    WhitespaceNormalizationMapper(),
    TextLengthFilter(min_len=10),
])

for s in result:
    print(s)
```

Useful when iterating on a recipe, writing unit tests for a custom OP, or running DJ as a step inside a larger Python program.

---

## Where to look things up

Bookmark these — they're the canonical sources of truth and are kept in sync with the code:

| Need                                              | Link                                                                                                  |
|---------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| Browse all OPs with descriptions                  | https://datajuicer.github.io/data-juicer/en/main/docs/Operators.html                                  |
| Every OP with every parameter as YAML             | https://github.com/datajuicer/data-juicer/blob/main/data_juicer/config/config_all.yaml                |
| API reference (Python classes)                    | https://datajuicer.github.io/data-juicer/en/main/api.html                                             |
| Developer guide (writing OPs, contributing)       | https://datajuicer.github.io/data-juicer/en/main/docs/DeveloperGuide.html                             |
| Dataset configuration (sources, mixture, validation) | https://datajuicer.github.io/data-juicer/en/main/docs/DatasetCfg.html                              |
| DJ format spec (incl. multimodal)                 | https://github.com/datajuicer/data-juicer/blob/main/tools/fmt_conversion/README.md                    |
| Cookbook (recipes, demos, competitions)           | https://github.com/datajuicer/data-juicer/blob/main/docs/tutorial/DJ-Cookbook.md                      |
| Recipe gallery (real recipes to fork)             | https://datajuicer.github.io/data-juicer-hub/en/main/docs/RecipeGallery.html                          |
| Distributed processing on Ray                     | https://datajuicer.github.io/data-juicer/en/main/docs/Distributed.html                                |

---

## Sanity checklist before suggesting code

When the user asks for a recipe or custom OP, walk this loop before answering:

1. **Is there a built-in OP for this?** Check `references/op-zoo.md` or the OperatorZoo URL above. The library has 200+ OPs and the right one often already exists.
2. **What modality and category does this fall into?** Text vs image/audio/video, and Filter vs Mapper vs Deduplicator. The category determines the base class for custom code.
3. **What's the user's data shape?** If it isn't already DJ format, suggest a format conversion tool from `tools/fmt_conversion/` before custom code.
4. **Are GPU / API-model OPs involved?** If yes, set `mem_required` so DJ can manage parallelism, and consider `executor_type: ray` if the dataset is large.
5. **Order the `process:` list deliberately.** Cheap CPU filters first, expensive GPU/API mappers next, dedup near the end. Wrong order is the most common cause of slow recipes.
