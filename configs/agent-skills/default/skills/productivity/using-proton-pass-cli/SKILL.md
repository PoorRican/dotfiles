---
name: using-proton-pass-cli
description: Use Proton Pass CLI for vaults, items, SSH keys and secret injection, especially when choosing session storage or troubleshooting secret references.
---

# Proton Pass CLI

`pass-cli` manages Proton Pass credentials and resolves secrets for processes or configuration files. The [upstream documentation](https://protonpass.github.io/pass-cli/) owns installation and command syntax; check the installed version's help for its supported options.

- Secret field references use `pass://vault/item/field`. Duplicate vault or item names can resolve to an unintended match; use share and item IDs when identity must be unambiguous. Section-qualified field names distinguish similarly named fields.
- `pass-cli run` resolves references in environment variables; `pass-cli inject` resolves only references wrapped in `{{ }}` and can write secret-bearing output to disk. Treat that output as a secret.
- On Linux the default kernel keyring loses its key on reboot. Set `PROTON_PASS_LINUX_KEYRING=dbus` for persistent D-Bus storage; an unavailable or locked Secret Service causes an error rather than a fallback. `PROTON_PASS_KEY_PROVIDER=fs` puts a plaintext key beside the encrypted session, while `PROTON_PASS_KEY_PROVIDER=env` uses `PROTON_PASS_ENCRYPTION_KEY`, exposing it to processes with access to that environment. Choose the backend for the environment and its threat model.
- Import a protected SSH key using the CLI's passphrase option rather than making an unencrypted temporary copy. Deleting such a copy does not guarantee erasure from snapshots, backups or storage media.
- Vault and item deletion can destroy credentials; confirm the target and the user's intent before destructive changes.
