# Proton Pass CLI — Installation & Configuration Reference

## Quick Install

**macOS and Linux:**
```bash
curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://proton.me/download/pass-cli/install.ps1 -OutFile install.ps1; .\install.ps1
```

The script auto-detects OS/architecture, downloads the latest stable binary, verifies integrity, and installs to PATH.

## Homebrew (macOS only)

```bash
brew install protonpass/tap/pass-cli
```

Update:
```bash
brew update && brew upgrade pass-cli
```

> **Note:** Homebrew installations cannot use `pass-cli update` or switch release tracks. Use `brew upgrade` instead.

## Installation Options

### Custom installation directory

```bash
# macOS/Linux
export PROTON_PASS_CLI_INSTALL_DIR=/custom/path
curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

# Windows
$env:PROTON_PASS_CLI_INSTALL_DIR="C:\custom\path"; .\install.ps1
```

### Beta channel

```bash
# macOS/Linux
curl -fsSL https://proton.me/download/pass-cli/install.sh | PROTON_PASS_CLI_INSTALL_CHANNEL=beta bash

# Windows
$env:PROTON_PASS_CLI_INSTALL_CHANNEL="beta"; .\install.ps1
```

Track switching via `pass-cli update --set-track` is only available for manual installations.

## Manual Installation

1. Download the versions listing: `https://proton.me/download/pass-cli/versions.json`
2. Download the binary for your platform.
3. Verify hash: `sha256sum pass-cli` and compare to versions.json.
4. `chmod +x pass-cli` (Unix).
5. Move to a PATH directory (e.g. `/usr/local/bin`).
6. Verify: `pass-cli --version`

## System Requirements

| Platform | Architectures |
|----------|--------------|
| macOS    | x86_64, arm64 (Apple Silicon) |
| Linux    | x86_64, aarch64 |
| Windows  | x86_64 |

**Script dependencies:** `curl` and `jq` (macOS/Linux). No extra deps on Windows.

## Configuration

### Logging

```bash
# Levels: trace, debug, info, warn, error, off
export PASS_LOG_LEVEL=debug
```

Logs are sent to `stderr` so they don't interfere with piping.

### Session storage directory

Default locations:
- **macOS:** `~/Library/Application Support/proton-pass-cli/.session/`
- **Linux:** `~/.local/share/proton-pass-cli/.session/`

Override:
```bash
export PROTON_PASS_SESSION_DIR='/custom/path'
```

### Secure key storage (`PROTON_PASS_KEY_PROVIDER`)

#### 1. Keyring (default)

```bash
export PROTON_PASS_KEY_PROVIDER=keyring  # or leave unset
```

Uses OS credential storage (macOS Keychain, Linux kernel keyring, Windows Credential Manager).

- **Linux caveat:** Uses kernel keyring (no D-Bus needed), but **secrets are cleared on reboot**. Docker containers cannot access the kernel secret service — use `fs` instead.

#### 2. Filesystem

```bash
export PROTON_PASS_KEY_PROVIDER=fs
```

Stores the encryption key at `<session-dir>/local.key` with `0600` permissions. Key is stored in plaintext — use when keyring is unavailable (Docker, headless servers).

#### 3. Environment variable

```bash
export PROTON_PASS_KEY_PROVIDER=env
export PROTON_PASS_ENCRYPTION_KEY=your-secret-key
```

Derives a 256-bit key from SHA256 of the variable. Generate a strong key:
```bash
dd if=/dev/urandom bs=1 count=2048 2>/dev/null | sha256sum | awk '{print $1}'
```

Best for CI/CD, containers, and automation where the key can be securely injected.

### Disable automatic update checks

```bash
export PROTON_PASS_NO_UPDATE_CHECK=1
```

## Environment Variables Summary

| Variable | Purpose |
|----------|---------|
| `PROTON_PASS_PASSWORD` | Account password (interactive login) |
| `PROTON_PASS_PASSWORD_FILE` | Path to file containing password |
| `PROTON_PASS_TOTP` | TOTP code |
| `PROTON_PASS_TOTP_FILE` | Path to file containing TOTP code |
| `PROTON_PASS_EXTRA_PASSWORD` | Extra password for Pass |
| `PROTON_PASS_EXTRA_PASSWORD_FILE` | Path to file containing extra password |
| `PROTON_PASS_KEY_PROVIDER` | Key storage backend: `keyring`, `fs`, `env` |
| `PROTON_PASS_ENCRYPTION_KEY` | Encryption key (when using `env` provider) |
| `PROTON_PASS_SESSION_DIR` | Custom session storage directory |
| `PROTON_PASS_SSH_KEY_PASSWORD` | SSH key passphrase |
| `PROTON_PASS_SSH_KEY_PASSWORD_FILE` | Path to file containing SSH key passphrase |
| `PASS_LOG_LEVEL` | Logging verbosity |
| `PROTON_PASS_NO_UPDATE_CHECK` | Set to `1` to disable auto update checks |
| `PROTON_PASS_CLI_INSTALL_DIR` | Custom install dir (script only) |
| `PROTON_PASS_CLI_INSTALL_CHANNEL` | Install channel: `stable` or `beta` |

## Windows PowerShell Execution Policy

If the install script fails on Windows, check the execution policy:

```powershell
# Check current policy (run as Administrator)
Get-ExecutionPolicy

# Allow signed scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

The `install.ps1` is properly signed by Proton.
