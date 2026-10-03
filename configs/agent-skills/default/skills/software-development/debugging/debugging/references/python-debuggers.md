# Python debuggers

Scope: debugger selection and Python debugging failure modes that can make an interactive stop unavailable or misleading.

## Choosing a debugger

- For a local interactive frame, `pdb` offers a built-in REPL; `python -m pdb` can launch a script without adding a source breakpoint. For IDE integration, remote attachment, or thread-aware inspection, `debugpy` speaks DAP. (src: python-debugpy)
- For terminal-driven inspection when a DAP client is unnecessary, `remote-pdb` can be simpler than building a DAP client; `debugpy` is appropriate when IDE/DAP integration or thread-aware debugging is needed. (src: python-debugpy)



## Breakpoint and process behavior

- `debugpy.listen()` opens the adapter but does not pause the target; execution can pass the intended breakpoint before a client attaches unless the code waits for the client. (src: python-debugpy)
- Pytest-xdist workers do not provide an interactive pdb prompt, so interactive pdb requires running the test outside xdist workers. (src: python-debugpy)
- `breakpoint()` and `set_trace()` can block CI or another non-interactive run; committed hooks can therefore hang those environments. `PYTHONBREAKPOINT=0` disables `breakpoint()` calls, so a breakpoint that is never reached may be an environment setting rather than control-flow evidence. (src: python-debugpy)

- `pdb` debugs the current thread and does not automatically follow forked or multiprocessing children; for threaded code, debugpy is thread-aware, while a child process needs its own debugging hook or attachment. (src: python-debugpy)
