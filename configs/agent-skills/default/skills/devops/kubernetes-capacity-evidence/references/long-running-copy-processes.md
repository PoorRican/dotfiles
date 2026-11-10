# Long-running copy process custody

Scope: tracking authorized long copies and their verification.

- Capture output and process identity in a tracked process from the outset. A client or tool timeout does not prove a remote copy stopped; inspect process identity and arguments before retrying. A failed unprivileged `kill -0` can indicate EPERM for a live process, not completion; inspect with `ps` and suitable privileges.
- A timed-out recursive size scan is incomplete evidence, not zero usage. Bound expensive scans and report timeout separately.
