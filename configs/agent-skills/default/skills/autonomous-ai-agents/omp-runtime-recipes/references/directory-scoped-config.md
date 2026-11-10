# Directory-scoped omp settings and memory

Scope: keep a setting (for example the memory backend) off globally and enable it only under one workspace tree, using a config overlay that direnv loads.

## Mechanics

- omp's native `<cwd>/.omp/config.yml` discovery does not walk ancestors, so a parent workspace's overlay is not seen from a child directory. Scope settings to a tree by appending the absolute overlay path to `PI_CONFIG_FILES` from the workspace's `.envrc`:
  ```bash
  export PI_CONFIG_FILES="${PI_CONFIG_FILES:+${PI_CONFIG_FILES}:}/absolute/workspace/.omp/config.yml"
  ```
  `PI_CONFIG_FILES` is a colon-separated overlay list on Unix, loaded before an explicit CLI `--config`.
- Set the global value with `omp config set memory.backend off`, run outside any project overlay so the effective-value output is not confused.
- The overlay (`<workspace>/.omp/config.yml`) sets `memory.backend: hindsight` and may also hold the server, token, bank and scoping settings locally. Keep any token file at mode 600 and never print token values in reports.
- Check that direnv is installed and the shell has its hook, then authorize the file with `direnv allow <workspace>`.

## Verification

- Child `.envrc` files stop parent discovery unless they call `source_up`. Do not claim every descendant inherits the overlay without exercising a representative child; preserve unrelated child environments unless migration is requested.
- Verify with `direnv exec <workspace> omp config get memory.backend --json` and the same command in a descendant, and verify outside the scoped environment that the backend stays off.
- For bank, server or token checks use `omp config list --json` and select safe fields; credential entries show `redacted: true` instead of values.

## Behavior to expect

- A missing or invalid overlay file is a hard error, not a silent fallback.
- Running omp processes do not acquire a newly exported environment; relaunch from a direnv-enabled shell.
- Disabling a backend does not delete stored memories.
- Treat the current files as authoritative rather than assuming an earlier setup still holds; re-read them before editing.
