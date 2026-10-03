# Agent harness testing

Scope: Semantics that can make interactive editor and terminal harness assertions look correct while observing the wrong state.

## Native editor fixture semantics

- Helix `PrevWordStart` and `PrevLongWordStart` can produce a reverse range such as `#[|hello ]#world`; normalizing it to a forward selection changes native cursor semantics. (src: helix-trial-oracle-fixtures; 2026-08-31)
- Counted `w`/`e` motions replace the range on each iteration, so the final iteration determines the marker; for example, `2w` on “This is just” lands on “is”, not the full traversed span. (src: helix-trial-oracle-fixtures; 2026-08-31)
- An empty `i<Esc>` preserves a reverse insert range; collapsing it to a forward minimum-width range changes native cursor semantics. (src: helix-trial-oracle-fixtures; 2026-08-31)
- Trial fixture JSON is emitted on stdout while human PASS/Summary text is on stderr; comparisons that combine the streams can mistake presentation output for fixture data. (src: helix-trial-oracle-fixtures; 2026-08-31)

## Real interactive terminal observation

- Python's standard-library `pty` can fork an interactive process and send key bytes after launch; a conventional shell PTY launch does not itself provide that post-launch input channel. (src: interactive-omp-smoke; 2026-07-05)
- Captured terminal text can contain ANSI, OSC, or APC control sequences around visible status, so an unnormalized plain-text match can miss a visible marker. (src: interactive-omp-smoke; 2026-07-05)
- Startup assertions based on observed prompt/status output are more reliable than a fixed startup delay; an isolated bounded run also prevents a smoke harness from waiting indefinitely. (src: interactive-omp-smoke; 2026-07-05)

## Suite-specific live session state

These observations belong to the live agent-rail suite on Zellij 0.44.3, not to Zellij generally.

- After an inactive close, the Exited row remains selected; a PTY lifecycle glyph such as `> × session 2` is not the suite's “Press x again” close confirmation. (src: zellij-agent-rail-live-suite; 2026-08-31)
- If the `omp` executable is absent, the suite can still observe a visible, held, exited active session with its slot suppressed; absence of the executable alone is not evidence that the session should auto-close. (src: zellij-agent-rail-live-suite; 2026-08-31)
- A pre-action pane with T1 visible while its slot is suppressed is not proof of a successful post-close state; emitting `CloseOwnedTerminal` from visibility alone could close T1 while leaving the slot suppressed. (src: zellij-agent-rail-live-suite; 2026-08-31)
- A stale “close” elsewhere in a captured screen can falsely satisfy a close-confirmation check; the suite distinguishes fresh PTY bytes containing “Press x” after output is pumped. (src: zellij-agent-rail-live-suite; 2026-08-31)
