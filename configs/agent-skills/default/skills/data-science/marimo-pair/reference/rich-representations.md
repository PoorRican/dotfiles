# Rich representations

Choose the smallest representation that fits: `mo.ui.*` for built-in controls, `mo.Html` or an object's `_display_()` for simple output, and anywidget when custom synchronized interaction needs Python and JavaScript. Some libraries expose a Jupyter widget as their default representation but provide a separate anywidget instance that marimo can render; inspect the object and its available accessors rather than assuming the wrapper is renderable.

For anywidget, a traitlet tagged `sync=True` is shared between Python and JavaScript. JavaScript changes require `model.set(...)` and `model.save_changes()`. In `_esm`, `initialize` owns per-widget resources and `render` runs per view; return cleanup functions for timers and DOM listeners when views or widgets are removed.
`model.on()` handlers are cleaned up when a view is removed; DOM `addEventListener` handlers are not. For example, use an `AbortController` and return a function that aborts it from `render`.

```js
export default () => ({
  initialize({ model }) {
    // Set up resources shared by views.
    return () => { /* clean up shared resources */ };
  },
  render({ model, el }) {
    const controller = new AbortController();
    el.addEventListener("click", () => {
      model.set("selected", true);
      model.save_changes();
    }, { signal: controller.signal });
    return () => controller.abort();
  }
});
```


To make a particular widget trait drive downstream marimo cells, initialize `mo.state` from the current trait, observe that trait, and read the state getter in a downstream cell:

```python
get_selection, set_selection = mo.state(widget.selection)
widget.observe(lambda _: set_selection(widget.selection), names=["selection"])
```

Alternatively, `mo.ui.anywidget(widget)` exposes synced traits together as a value dictionary. Choose the integration that matches whether individual traits or the whole widget should drive reactivity. Programmatic updates to anywidget traits use attribute assignment; built-in marimo UI elements use code mode's `set_ui_value`.
Read `get_selection()` in a separate downstream cell. Initialize state from the current widget trait and read the trait directly in the observer; choose one integration strategy per widget rather than mixing them.


Reduce or filter data in Python before transferring it to the browser. If the widget genuinely needs substantial row-level data and JSON serialization is costly, Arrow IPC bytes can be transferred through a synced trait and decoded in JavaScript; the extra dependencies are not warranted for every table.

For a Polars frame, `df.write_ipc(None).getvalue()` produces IPC bytes. Store them in `traitlets.Any().tag(sync=True)` and decode in JavaScript with:

```js
import { tableFromIPC } from "https://esm.sh/@uwdata/flechette@2";
const table = tableFromIPC(new Uint8Array(model.get("_ipc").buffer));
```
