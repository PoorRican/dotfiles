# Live notebook pairing

## Connect

Use `bash scripts/discover-servers.sh` to find locally registered servers, or target a known server with `scripts/execute-code.sh --url URL`; `--port` selects a registered local server and `--session` selects a session. If several targets are possible, identify the intended notebook rather than guessing. The scripts use `curl` and `jq`; discovery can remove stale local registry entries.

For an authenticated server, supply `MARIMO_TOKEN` in the environment; `--token` also works but may expose it in process listings. Token-authenticated servers may be absent from the local registry, so a missing entry does not prove the server is absent: use its explicit URL. A server with no active sessions needs a notebook opened in the browser; supplying a session ID does not create one.

If the user wants a new notebook, invoke marimo with the project's environment and authentication settings. Disabling token authentication solely for discovery exposes the server to anyone who can reach it; prefer a known authenticated URL. A notebook with PEP 723 inline dependencies needs `--sandbox` to use its isolated dependency environment rather than the ambient project environment.
Start in edit mode without `--headless` unless requested. Check the project's `pyproject.toml` or `.venv` for marimo before choosing the runner; a non-default dependency group needs `uv run --group GROUP marimo edit notebook.py`. A project using pixi can use `pixi run marimo edit notebook.py`. Outside a project, `uvx marimo@latest edit notebook.py --sandbox` starts an isolated notebook. For an existing PEP 723 notebook, retain `--sandbox` even inside a project.


Use `-c` for short code and a quoted heredoc or file for multiline or shell-sensitive code:

```sh
bash scripts/execute-code.sh --url http://localhost:2718 <<'PY'
print(df.head())
PY
```

## Scratchpad and persistent changes

Execution runs in a scratchpad with a shallow copy of kernel globals: new bindings and rebindings disappear after the call, but in-place mutations can affect notebook-owned objects. Output includes scratchpad output and output from notebook cells the call triggers.

For persistent notebook changes use `marimo._code_mode`, a private, unstable API. Inspect `help(cm)` in the active kernel because its interface can change; keep the import in the scratchpad, not in notebook cells or user libraries. The scratchpad supports top-level `async with`; avoid `asyncio.run` in the running event loop.

```python
import marimo._code_mode as cm

async with cm.get_context() as ctx:
    cid = ctx.create_cell("x = df.head()", hide_code=False)
    ctx.run_cell(cid)
```

Mutation methods queue synchronous operations. On normal context exit, structural changes are validated and applied, queued cells run, and dependents may rerun; an exception discards the queue. Creating or editing a cell does not run it by itself, and structural validation does not guarantee successful execution. Later in the same scratchpad call, use `ctx.globals` to read values created by the run: the scratchpad namespace was copied before it ran.
`create_cell` defaults to `hide_code=True`; pass `hide_code=False` to keep the editor expanded. For dependency changes, `ctx.packages.add()` and `ctx.packages.remove()` manage packages in the live session.

## Notebook shape

`ctx.cells` is the document view; `ctx.graph` is the dataflow view. Cell IDs are opaque strings returned by `create_cell` or obtained from the notebook:

```python
for cell in ctx.cells:
    print(cell.id, cell.name, cell.code, cell.config, cell.status, cell.errors)
ctx.cells["setup"]       # by name
ctx.cells[0]             # by position
list(ctx.cells.keys())   # IDs in notebook order
ctx.graph.ancestors(cid)
ctx.graph.descendants(cid)
```

Before `ctx.edit_cell`, read `ctx.cells[...]` again: another editor may have changed the body since the previous scratchpad call. Deleting a cell removes the globals it defines.


## Reactive edits

Inspect current cell code with `ctx.cells` before replacing it; submit the full cell body, not the saved-file `@app.cell` wrapper. `ctx.graph.cells[cid].defs` and `.refs` show definitions and references; `ctx.graph.descendants(cid)` shows downstream cells to consider before destructive deletion. Reuse existing imports and inspect the owner of a name before editing.

Public names, including imports and loop variables, have one owning cell. A duplicate definition fails validation: edit its owner or give the new result a distinct name. Names beginning with `_` are local to their defining cell; use public names for values other cells need. Cycles and wildcard imports also prevent graph construction.

A setup cell runs before other cells and cannot reference variables they define. Reorganize imports into one only when that improves the notebook; edit the existing setup cell rather than creating a duplicate. When adding a package during a session, a library may retain cached optional-dependency availability; a kernel restart may be needed.

Set `mo.ui.*` values with `ctx.set_ui_value(element, value)` inside a code-mode context; set anywidget synced traitlets as Python attributes. For persistent dependency changes, use the code-mode package interface when available and discuss non-obvious changes with the user.
