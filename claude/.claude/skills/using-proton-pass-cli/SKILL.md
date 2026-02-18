---
name: using-proton-pass-cli
description: Interact with Proton Pass via the `pass-cli` command-line tool. Use this skill when the user wants to manage passwords, vaults, items, SSH keys, secret injection, or any credential management through the Proton Pass CLI. Triggers on mentions of pass-cli, proton pass, secret references, pass:// URIs, vault management, or SSH agent integration with Proton Pass.
---

# Proton Pass CLI Skill

Use the `pass-cli` command-line tool to manage vaults, items, secrets, SSH keys, and sharing in Proton Pass.

## Prerequisites

- `pass-cli` must be installed. If not installed, read the `INSTALLATION.md` file in this skill directory for platform-specific installation instructions.
- The user must be authenticated. Test with `pass-cli test`. If not authenticated, guide them through login.

## Authentication

### Web login (recommended — supports SSO and hardware keys)

```bash
pass-cli login
```

Prints a URL to complete auth in a browser.

### Interactive login (terminal-only)

```bash
pass-cli login --interactive user@proton.me
```

Prompts for password, TOTP (if enabled), and extra password (if configured).

### Automated login (scripting)

Credentials are resolved in order: environment variable → file → interactive prompt.

```bash
export PROTON_PASS_PASSWORD='...'
export PROTON_PASS_TOTP='123456'
export PROTON_PASS_EXTRA_PASSWORD='...'
pass-cli login --interactive user@proton.me
```

File-based variants: `PROTON_PASS_PASSWORD_FILE`, `PROTON_PASS_TOTP_FILE`, `PROTON_PASS_EXTRA_PASSWORD_FILE`.

### Session management

```bash
pass-cli test          # Verify session is valid
pass-cli info          # Show user ID, username, email, release track
pass-cli user info     # Detailed account info (plan, features, storage)
pass-cli logout        # End session and remove local data
pass-cli logout --force  # Force local cleanup even if remote logout fails
```

## Settings (Persistent Defaults)

Configure a default vault and output format to reduce flags on every command:

```bash
pass-cli settings view                                          # View current settings
pass-cli settings set default-vault --vault-name "Personal"     # Set default vault
pass-cli settings set default-format json                       # Set default output format (human|json)
pass-cli settings unset default-vault                           # Clear default vault
pass-cli settings unset default-format                          # Clear default format
```

When a default vault is set, commands like `item list`, `item create`, `item view`, `item update` work without `--share-id` or `--vault-name`.

## Vault Management

Vaults are containers that organize items. Most vault commands accept `--share-id SHARE_ID` or `--vault-name NAME` (mutually exclusive).

```bash
pass-cli vault list [--output json]
pass-cli vault create --name "My Vault"
pass-cli vault update --vault-name "Old" --name "New"
pass-cli vault delete --vault-name "Old Vault"               # ⚠️ Permanent — deletes all items
```

### Vault sharing

```bash
pass-cli vault share --vault-name "Team" colleague@co.com --role editor
# Roles: viewer (default), editor, manager
```

### Vault members

```bash
pass-cli vault member list --vault-name "Team" [--output json]
pass-cli vault member update --share-id "..." --member-share-id "..." --role editor
pass-cli vault member remove --share-id "..." --member-share-id "..."
```

### Vault transfer

```bash
pass-cli vault transfer --vault-name "My Vault" "member_share_id"
```

## Item Management

Items are the fundamental data units: logins, notes, credit cards, aliases, SSH keys.

### Listing items

```bash
pass-cli item list                                  # Uses default vault
pass-cli item list "Personal Vault"                 # By vault name
pass-cli item list --share-id "abc123" --output json
```

### Creating login items

```bash
pass-cli item create login \
  --title "GitHub" \
  --username "myuser" \
  --password "mypassword" \
  --url "https://github.com"

# With generated password
pass-cli item create login --title "Account" --username "me" --generate-password

# Custom password generation: "length,uppercase,symbols"
pass-cli item create login --title "Account" --username "me" --generate-password="20,true,true"

# With passphrase
pass-cli item create login --title "Account" --username "me" --generate-passphrase="5"
```

### Templates

```bash
pass-cli item create login --get-template > template.json
# Edit template.json
pass-cli item create login --from-template template.json --vault-name "Personal"

# Template JSON format:
# {"title":"...","username":"...","email":"...","password":"...","urls":["https://..."]}
```

### Viewing items

```bash
pass-cli item view --vault-name "MyVault" --item-title "MyItem"
pass-cli item view --share-id "abc123" --item-id "item456"
pass-cli item view "pass://MyVault/MyItem"              # By secret reference
pass-cli item view "pass://abc123/item456/password"     # Specific field
pass-cli item view --share-id "abc123" --item-id "item456" --field "username"
```

### Updating items

```bash
pass-cli item update --vault-name "Personal" --item-title "GitHub" \
  --field "password=newpass123"

# Multiple fields
pass-cli item update --share-id "abc123" --item-id "item456" \
  --field "username=newuser" \
  --field "password=newpass" \
  --field "email=new@example.com"

# Custom fields (created if they don't exist)
pass-cli item update --share-id "abc123" --item-id "item456" \
  --field "api_key=sk_live_abc123"

# Note: time and TOTP fields cannot be updated via CLI
```

### Deleting items

```bash
pass-cli item delete --share-id "abc123" --item-id "item456"  # ⚠️ Permanent
```

### TOTP codes

```bash
pass-cli item totp --item-title "WithTOTPs"
pass-cli item totp "pass://TOTP export/WithTOTPs"
pass-cli item totp "pass://TOTP export/WithTOTPs/TOTP 1"
pass-cli item totp "pass://vault/item" --output json | jq -r '."totp"'
```

### Email aliases

```bash
pass-cli item alias create --prefix "shopping" --vault-name "Personal"
```

### Sharing items

```bash
pass-cli item share --share-id "abc123" --item-id "item456" colleague@co.com --role editor
```

### Attachments

```bash
pass-cli item attachment download --share-id "abc123" --item-id "item456" --attachment-id "att789"
```

## SSH Key Management

### Generate a new SSH key

```bash
pass-cli item create ssh-key generate \
  --title "GitHub Deploy Key" \
  --key-type ed25519              # ed25519 (default), rsa2048, rsa4096

# With passphrase protection
pass-cli item create ssh-key generate --title "Key" --password

# Passphrase via env: PROTON_PASS_SSH_KEY_PASSWORD or PROTON_PASS_SSH_KEY_PASSWORD_FILE
```

### Import an existing SSH key

```bash
pass-cli item create ssh-key import \
  --from-private-key ~/.ssh/id_ed25519 \
  --title "My SSH Key"

# Passphrase-protected key
pass-cli item create ssh-key import \
  --from-private-key ~/.ssh/id_ed25519 \
  --title "Protected Key" \
  --password
```

### Recommended import workflow for passphrase-protected keys

```bash
# 1. Create unencrypted copy
cp ~/.ssh/id_ed25519 /tmp/id_ed25519_temp
ssh-keygen -p -f /tmp/id_ed25519_temp -N ""

# 2. Import
pass-cli item create ssh-key import --from-private-key /tmp/id_ed25519_temp --title "My Key"

# 3. Securely delete temp copy
shred -u /tmp/id_ed25519_temp  # Linux
rm -P /tmp/id_ed25519_temp     # macOS
```

## SSH Agent Integration

### Load keys into existing SSH agent

```bash
pass-cli ssh-agent load                                  # All vaults
pass-cli ssh-agent load --vault-name MySshKeysVault      # Specific vault
```

Requires `SSH_AUTH_SOCK` to be set.

### Run Proton Pass CLI as the SSH agent

```bash
pass-cli ssh-agent start
# Then in another terminal:
export SSH_AUTH_SOCK=$HOME/.ssh/proton-pass-agent.sock

# Options:
pass-cli ssh-agent start --vault-name MySshKeysVault
pass-cli ssh-agent start --socket-path /custom/path.sock
pass-cli ssh-agent start --refresh-interval 7200          # Seconds between key scans
pass-cli ssh-agent start --create-new-identities MySshKeysVault  # Auto-save ssh-add keys
```

## Secret References & Injection

### Secret reference syntax

```
pass://vault-identifier/item-identifier/field-name
```

- Vault and item can be referenced by name or ID
- Field names are case-sensitive
- Common fields: `username`, `password`, `email`, `url`, `note`, `totp`
- Custom fields: use the exact field name

### `view` — Display a secret value

```bash
pass-cli item view "pass://Production/Database/password"
```

### `run` — Inject secrets into environment variables

```bash
export DB_PASSWORD='pass://Production/Database/password'
pass-cli run -- ./my-app

# With .env files
pass-cli run --env-file .env.secrets -- ./my-app

# Multiple env files (later overrides earlier)
pass-cli run --env-file base.env --env-file secrets.env -- node server.js

# Disable secret masking in stdout/stderr
pass-cli run --no-masking -- ./my-app
```

By default, secret values in stdout/stderr are masked as `<concealed by Proton Pass>`.

Multiple `pass://` references can appear in a single env var value:
```
DATABASE_URL="postgresql://user:pass://vault/db/password@localhost/db"
```

### `inject` — Process template files

Template syntax uses `{{ pass://... }}` (double braces required):

```yaml
# config.yaml.template
database:
  username: {{ pass://Production/Database/username }}
  password: {{ pass://Production/Database/password }}
api:
  key: {{ pass://Work/API Keys/api_key }}
# Plain pass:// URIs without {{ }} are ignored
```

```bash
pass-cli inject --in-file config.yaml.template --out-file config.yaml
pass-cli inject --in-file template.txt --out-file config.txt --force  # Overwrite
pass-cli inject --in-file template.txt --out-file config.txt --file-mode 0644

# From stdin
cat template.txt | pass-cli inject
pass-cli inject << EOF
{"password": "{{ pass://Vault/Item/password }}"}
EOF
```

Default output file permissions: `0600`.

## Shares & Invitations

### Shares

```bash
pass-cli share list [--output json]
```

Shows all vault and item shares you have access to, with roles (Owner, Manager, Editor, Viewer).

### Invitations

```bash
pass-cli invite list [--output json]
pass-cli invite accept --invite-token "token123"
pass-cli invite reject --invite-token "token123"
```

## Password Generation & Scoring

These commands work without authentication.

```bash
# Random password
pass-cli password generate random
pass-cli password generate random --length 20 --uppercase true --symbols true

# Passphrase
pass-cli password generate passphrase
pass-cli password generate passphrase --count 5 --separator "-" --capitalize true --numbers true

# Score a password
pass-cli password score "mypassword123"
pass-cli password score "MyP@ss!" --output json
```

## Updating the CLI

```bash
pass-cli update                     # Interactive update
pass-cli update --yes               # Non-interactive
pass-cli update --set-track beta    # Switch to beta track
pass-cli update --set-track stable  # Switch back to stable
pass-cli info                       # Check current release track
```

> `update` and track switching only work for manual installations, not Homebrew/package manager installs.

## Common Patterns

### Session validation in scripts

```bash
if pass-cli test > /dev/null 2>&1; then
    echo "Authenticated"
else
    echo "Login required"
    pass-cli login --interactive user@proton.me
fi
```

### Full automated workflow

```bash
#!/bin/bash
export PROTON_PASS_PASSWORD_FILE='/secure/creds/password.txt'
export PROTON_PASS_TOTP_FILE='/secure/creds/totp.txt'
pass-cli login --interactive user@proton.me

pass-cli vault create --name "Deploy Keys"
pass-cli item create login --vault-name "Deploy Keys" \
  --title "Production DB" --username "admin" --generate-password \
  --url "https://db.example.com"

pass-cli run --env-file .env.production -- ./deploy.sh
pass-cli logout
```

### CI/CD secret injection

```bash
pass-cli run --env-file .env.secrets -- ./deploy.sh
```

## Important Notes

- **Mutually exclusive flags:** Most commands that accept `--share-id` and `--vault-name` require exactly one (not both). Similarly for `--item-id` and `--item-title`.
- **Default vault/format:** Use `pass-cli settings set` to avoid repeating vault and format flags.
- **Output formats:** Most listing/view commands support `--output human` (default) and `--output json`.
- **Destructive operations:** `vault delete` and `item delete` are permanent and cannot be undone.
- **Secret reference field requirement:** `pass://vault/item` alone is invalid — a field name is always required: `pass://vault/item/field`.
