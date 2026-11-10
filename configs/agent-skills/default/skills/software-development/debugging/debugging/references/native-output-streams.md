# Native output streams

Scope: keeping a strict stdout protocol (JSON-over-pipe RPC, machine-parsed CLI output) clean when native libraries write to file descriptors behind the language runtime's back.

## Stream ownership

- `contextlib.redirect_stdout` only replaces Python's `sys.stdout`. A native library such as DuckDB writes its progress output to file descriptor 1 directly, so it still corrupts a strict-JSON stdout. (src: native-stream-ownership; 2026-10)
- Fix ownership at the descriptor level: duplicate fd 1 for the protocol channel, `dup2(fd2, fd1)` around the native call so stray native output lands on stderr, and restore in a `finally`. Forward native stderr on the host side instead of discarding it, and test with real native writes rather than a Python-level fake. (src: native-stream-ownership; 2026-10)
- Library progress settings can be connection-local: DuckDB's `progress_bar_time` is a per-connection `SET`, so configuring one connection does not silence another. (src: native-stream-ownership; 2026-10)
