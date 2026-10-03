# Secrets handling

Scope: Prevent secret exposure during remote credential transfer and distinguish byte identity from consumer usability.

## Transfer and permissions

- A secret expanded into command argv can appear in process command lines; for credential transfer and later validation, keep the value out of argv and send it over stdin or let the consumer read a protected file. (src: verified-remote-secret-install; 2026-08-26)
- For root-only credential files, `install -m 0600` sets restrictive permissions at creation. `tee` may create a world-readable file under the default umask before a later `chmod` closes the exposure window. (src: verified-remote-secret-install; 2026-08-26)
- A caller-shell redirection is performed before `sudo` runs and is not elevated; the privileged command itself must open a root-only source when hashing, statting, or reading it. (src: verified-remote-secret-install; 2026-08-26)

## What proves a secret arrived usable

- SSH success or destination-file existence alone does not prove transfer integrity: require a non-empty length and full-digest equality, then verify the consumer-equivalent read path. (src: verified-remote-secret-install; 2026-08-26)
- Credential validation must preserve the same exposure boundary as installation: expanding the secret into a client argument can leak it through process command lines even when the stored file is protected. (src: verified-remote-secret-install; 2026-08-26)
