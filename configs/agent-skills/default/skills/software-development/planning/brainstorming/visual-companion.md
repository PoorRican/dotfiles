# Visual Companion

Offer the browser companion just in time, when a question is genuinely easier to answer visually, such as a layout comparison or architecture diagram. Make the offer a separate message and wait for the answer. If the user declines, continue in text and don't offer again unless they raise it. Even after acceptance, keep requirements and conceptual trade-offs in text.

## Start

After the user agrees, run the launcher from this skill directory with the project root as `PROJECT`:

```bash
scripts/start-server.sh --project-dir "$PROJECT" --open
```

The JSON response contains `url`, `screen_dir`, and `state_dir`. Share the complete URL, including its session key; HTTP and WebSocket requests require it. The first screen triggers browser opening, but remote or headless sessions may require the user to open the URL themselves. Project sessions persist under `.superpowers/brainstorm/`.

The server must survive between turns. If the environment reaps background processes, use `--foreground` with its persistent-process facility. The server binds loopback by default; for remote access, select an appropriate `--host` and `--url-host` and consider who can reach the service.

## Show and iterate

1. Check that `state_dir/server-info` exists and `state_dir/server-stopped` does not before referring to the URL or publishing a screen. If stopped, restart using the same project directory. A restart tries the saved port and key, but can fall back to a different port if it is occupied; use the new response's URL and directories.
2. Write a new HTML file in `screen_dir` for each screen; the server serves the newest file. A fragment is wrapped in the supplied frame and styles; a document beginning with `<!DOCTYPE` or `<html` is served as a full page with the helper injected. Use the frame template and helper script for available styles and selection controls.
3. Share the complete URL, summarize the screen, and ask for feedback in the conversation. On the next turn, read `state_dir/events` if present and combine click events with the user's text; the text is primary. Events are cleared when a new screen is published.
4. Iterate with a new file when feedback changes the screen. When returning to a text-only discussion, publish a waiting screen so the browser does not display a stale choice.

Scale fidelity to the question: wireframes for layout, detailed visuals for polish. Include the question on the screen and use real content when placeholders would hide a design issue.

For selectable options, the bundled helper expects `data-choice` and `onclick="toggleSelect(this)"`; add `data-multiselect` to `.options` or `.cards` for multiple selections:

```html
<h2>Which layout works better?</h2>
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content"><h3>Single column</h3></div>
  </div>
</div>
```

## Stop

Run `scripts/stop-server.sh "$SESSION_DIR"` when finished, with `SESSION_DIR` set to the parent of `state_dir`. Project-session files persist after shutdown.

The bundled `scripts/frame-template.html` and `scripts/helper.js` define the available markup and interaction helpers.
