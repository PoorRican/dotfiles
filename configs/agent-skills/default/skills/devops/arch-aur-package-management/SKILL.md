---
name: arch-aur-package-management
description: "Use when setting up, repairing, or using Arch User Repository (AUR) workflows on Arch Linux: prerequisites, yay/paru helper installation, PKGBUILD downloads, libalpm rebuilds after pacman upgrades, and verification."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [arch, aur, pacman, yay, paru, makepkg, package-management]
    related_skills: [nix-flake-dotfiles-maintenance]
---

# Arch AUR Package Management

## Overview

Use this skill for Arch Linux tasks involving the Arch User Repository (AUR): setting up AUR access, installing or repairing an AUR helper, downloading PKGBUILDs, building packages locally, and verifying that the helper works after pacman/libalpm changes.

The AUR is not a binary repository. It provides build recipes (`PKGBUILD` plus related files). Helpers such as `yay` and `paru` automate searching, cloning, dependency resolution, building with `makepkg`, and installing with `pacman`, but the durable primitives are still `git`, `base-devel`, `makepkg`, and `pacman`.

## When to Use

- User asks to "set up AUR", "download packages from AUR", "install yay/paru", or "use AUR packages".
- `yay`, `paru`, or another helper is installed but fails after a system upgrade.
- User wants to clone/download AUR build files without installing the package.
- A package exists only in AUR and needs to be built locally.
- You need to explain the difference between official Arch repos, AUR recipes, and local built packages.

Do **not** use this skill for:

- Nix/NixOS package management unless the task explicitly bridges Arch and Nix.
- Non-Arch distributions.
- General Linux package install questions that do not involve AUR.

## Prerequisite Discovery

Always inspect the live system before giving commands. Useful checks:

```bash
. /etc/os-release
printf 'OS=%s %s\n' "${NAME:-unknown}" "${VERSION_ID:-rolling}"
printf 'ID=%s\n' "${ID:-unknown}"

command -v pacman || true
command -v sudo || true
command -v git || true
command -v makepkg || true
command -v yay || true
command -v paru || true

pacman -Q base-devel git fakeroot binutils gcc make pkgconf 2>&1 || true
pacman -Q pacman yay paru 2>&1 || true
```

If a helper binary exists, test it directly instead of assuming it works:

```bash
yay --version
paru --version
```

## Core Setup Pattern

1. **Confirm Arch Linux.** AUR workflows assume `pacman`/`makepkg` and an Arch-compatible system.
2. **Confirm build prerequisites.** The usual minimum is `base-devel` and `git`.
3. **Prefer an existing helper if it works.** Do not install a second helper just because one is absent; first check whether `yay` or `paru` is already present and functional.
4. **If no helper works, bootstrap one from AUR using plain `git` + `makepkg`.**
5. **Verify with both query and download workflows.** Search (`yay -Ss`) and clone (`yay -G`) exercise different code paths.

## Installing Prerequisites

If prerequisites are missing and the user authorized system package changes:

```bash
sudo pacman -Syu --needed base-devel git
```

Notes:

- `base-devel` is a package group/metapackage needed for many AUR builds.
- `makepkg` must not be run as root.
- `pacman -Syu` and `pacman -U` require sudo/root.

## Bootstrapping `yay`

Use this when no working helper exists, or when the installed helper is broken and cannot update itself.

```bash
workdir=$(mktemp -d /tmp/yay-aur.XXXXXX)
git clone https://aur.archlinux.org/yay.git "$workdir/yay"
cd "$workdir/yay"
makepkg -f --noconfirm --cleanbuild
sudo pacman -U ./yay-*.pkg.tar.zst
```

If sudo is not available but the user already has `~/.local/bin` early in `PATH`, a user-local emergency helper can be installed by extracting only the built binary:

```bash
mkdir -p "$HOME/.local/bin"
pkg=''
for p in ./*.pkg.tar.zst; do
  case "$p" in *-debug-*) continue ;; *) pkg="$p"; break ;; esac
done
bsdtar -xOf "$pkg" usr/bin/yay > "$HOME/.local/bin/yay"
chmod 0755 "$HOME/.local/bin/yay"
"$HOME/.local/bin/yay" --version
```

This does **not** register the helper with pacman and should be described as a pragmatic user-local repair/shadowing approach. Prefer `sudo pacman -U` when the user wants the system package replaced.

## Bootstrapping `paru`

If the user prefers `paru`, the same pattern applies:

```bash
workdir=$(mktemp -d /tmp/paru-aur.XXXXXX)
git clone https://aur.archlinux.org/paru.git "$workdir/paru"
cd "$workdir/paru"
makepkg -f --noconfirm --cleanbuild
sudo pacman -U ./paru-*.pkg.tar.zst
```

## Incident Response: Check Whether Known Compromised AUR Packages Are Installed

Use this workflow when the user asks about an AUR supply-chain incident, malicious AUR adoptions, compromised AUR packages, or whether this Arch machine installed affected AUR packages.

1. **Ground the incident in Arch-controlled sources first.** Prefer Arch news, `aur-general` mailing-list threads, and maintainer-linked lists over reposted security blogs. Security blogs are useful for discovery, but the package names should come from Arch-maintainer-linked artifacts when available.
2. **Fetch the affected package list as data.** For HedgeDoc-style Arch notes, try the `/download` suffix to get raw markdown/text instead of scraping HTML. Keep the raw list in `/tmp` for follow-up inspection.
3. **Compare against both foreign and all installed packages.** `pacman -Qm` is the primary AUR/foreign check, but also compare against `pacman -Qq` so renamed/reclassified/local packages are not missed.
4. **Scan local traces for known payload indicators.** Search `/var/lib/pacman/local` and any AUR-helper cache such as `~/.cache/yay` for payload strings mentioned in the incident reports (for example, suspicious npm/bun packages or install snippets). Do not encode a single incident's payload names as universal rules; treat them as incident-specific indicators gathered during research.
5. **Check pacman logs for historical exposure.** Parse `/var/log/pacman.log` for install/upgrade/reinstall/remove actions involving affected package names, especially during the incident window. A clean current package list alone does not prove a package was never installed.
6. **Report uncertainty explicitly.** If Arch labels the affected list incomplete, say so. Distinguish “no known affected packages found” from a full forensic guarantee.

A concrete June 2026 AUR incident example, including source URLs and a reusable comparison script shape, is in `references/aur-compromise-check-2026-06.md`.

## Common Commands

Search official repos and AUR:

```bash
yay -Ss package-name
```

Install a package through the normal Arch/AUR helper path:

```bash
yay -S --needed package-name
```

If the package is in the official Arch repositories, `yay` delegates to `pacman`; this is still a reasonable first smoke-test path when the user explicitly wants to install manually before codifying declarative config.

Download/clone the AUR build files without installing:

```bash
yay -G package-name
```

Manually build from a cloned AUR directory:

```bash
cd package-name
makepkg -si
```

Upgrade official repo and AUR packages:

```bash
yay -Syu
```

Inspect a PKGBUILD before building:

```bash
less PKGBUILD
makepkg --printsrcinfo
```

## Repairing libalpm Breakage After pacman Upgrades

AUR helpers link against `libalpm`. After a pacman major upgrade, a helper may fail with an error like:

```text
yay: error while loading shared libraries: libalpm.so.15: cannot open shared object file: No such file or directory
```

Check the currently installed pacman library:

```bash
pacman -Q pacman yay paru 2>&1 || true
pacman -Ql pacman | grep -E 'libalpm\.so' || true
```

The durable fix is to rebuild the helper against the current `libalpm` using plain `git` + `makepkg`, then install the new package with `pacman -U` or, when sudo is unavailable and `~/.local/bin` shadows `/usr/bin`, temporarily install the rebuilt binary under `~/.local/bin`.

Do not encode the stale `libalpm` number as a rule. The actionable pattern is: helper linked to old `libalpm` → rebuild helper from AUR against current pacman.

See `references/yay-libalpm-rebuild.md` for a condensed session example.

## Verification Checklist

After setup or repair, verify:

- [ ] `command -v yay` or `command -v paru` resolves to the intended helper.
- [ ] `<helper> --version` prints successfully and shows the current libalpm version when available.
- [ ] Search works, for example `yay -Ss --aur package-name`.
- [ ] Download-only workflow works: `yay -G package-name` creates a directory containing `PKGBUILD`.
- [ ] If installed system-wide, `pacman -Q yay` or `pacman -Q paru` reports the expected version.
- [ ] If installed user-local, explain that the broken system package may still exist but is shadowed by `~/.local/bin`.

## Common Pitfalls

1. **Assuming an installed helper works.** Always run `yay --version`/`paru --version`; broken dynamic links are common after pacman/libalpm changes.

2. **Using a broad package glob that selects debug packages.** When extracting from `makepkg` output, skip `*-debug-*` packages or explicitly choose the non-debug package.

3. **Running `makepkg` as root.** Build as the normal user; only the final `pacman -U` install needs sudo.

4. **Treating AUR as a binary download source.** `yay -G` downloads build recipes; `yay -S` builds locally and installs the resulting package.

5. **Leaving a user-local repair unexplained.** If `~/.local/bin/yay` shadows `/usr/bin/yay`, say so and offer the system-wide `sudo pacman -U` command when appropriate.

6. **Failing because `/etc/os-release` lacks `VERSION_ID`.** Arch may not set `VERSION_ID`; use `${VERSION_ID:-rolling}` in shell snippets.

7. **Using `--noconfirm` when installing AUR packages that replace official packages.** Pacman conflict prompts such as `foo-git and foo are in conflict. Remove foo? [y/N]` default to No, so `--noconfirm` chooses No and the transaction fails. For `*-git` stacks that replace stable repo packages, run interactively and answer `y` to the explicit replacement/removal prompts; use yay's `--answerclean/--answerdiff/--answeredit` only to skip AUR helper menus, not pacman's conflict decisions.
