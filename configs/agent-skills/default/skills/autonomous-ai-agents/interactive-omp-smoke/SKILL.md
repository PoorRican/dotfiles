---
name: interactive-omp-smoke
description: Automate real OMP TUI extension smoke tests using a Python PTY harness when manual key input is required
---

# Interactive OMP Smoke Tests

Use this when an OMP extension requires real TUI verification: keypress sequences, modal editor behavior, or slash-command widgets. The normal Bash PTY can launch OMP but cannot feed input after launch, so use Python stdlib `pty`.

## Procedure

1. Build the extension first:

   ```sh
   bun run build
   ```

2. Spawn OMP in a pseudo-terminal from Python:

   ```python
   import os, pty, select, signal, time, re

   ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][\s\S]*?(?:\x07|\x1b\\)|\x1b[PX_^][\s\S]*?\x1b\\")

   def strip_ansi(text: str) -> str:
       return ANSI_RE.sub("", text)

   pid, fd = pty.fork()
   if pid == 0:
       os.execvp("omp", ["omp", "--extension", "./dist/index.js", "--no-session", "--max-time=20"])
   os.set_blocking(fd, False)
   ```

3. Read output nonblocking and wait for a prompt/status marker:

   ```python
   def read_available(fd, timeout=0.05):
       chunks = []
       end = time.time() + timeout
       while time.time() < end:
           ready, _, _ = select.select([fd], [], [], 0.01)
           if not ready:
               continue
           try:
               data = os.read(fd, 65536)
           except (BlockingIOError, OSError):
               break
           if not data:
               break
           chunks.append(data.decode("utf-8", "ignore"))
       return "".join(chunks)
   ```

4. If the splash screen appears, send Enter when stripped output includes `press enter to skip`.

5. Send key bytes with small delays:

   ```python
   for key in [b"i", b"a", b"b", b"c", b"\x1b", b"v", b"l", b"m", b"("]:
       os.write(fd, key)
       time.sleep(0.08)
   ```

6. Verify stripped output contains the expected prompt/status text, e.g. `(a)bc` and `-- reg "`.

7. For slash-command widgets from normal mode, first enter insert mode, then type the slash command and Enter:

   ```python
   os.write(fd, b"i/modal-editor:help\r")
   ```

8. Terminate cleanly at the end:

   ```python
   os.kill(pid, signal.SIGTERM)
   os.close(fd)
   ```

## Notes

- Use this only for real interactive TUI verification. Unit-level editor tests are faster for pure state-machine behavior.
- Strip ANSI/OSC/APC before searching output; OMP emits rich terminal sequences.
- Keep waits condition-based (`wait until output contains X`) instead of sleeping blindly.
- Use `--no-session` and `--max-time` to keep smoke runs isolated and bounded.
