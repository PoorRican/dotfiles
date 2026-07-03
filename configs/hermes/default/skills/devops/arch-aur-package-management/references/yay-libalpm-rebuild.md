# Session note: rebuilding yay after libalpm mismatch

## Scenario

On Arch Linux, `yay` was already installed but failed at runtime:

```text
yay: error while loading shared libraries: libalpm.so.15: cannot open shared object file: No such file or directory
```

System checks showed current pacman provided `libalpm.so.16`, while the installed `yay` package was older and linked to `libalpm.so.15`.

## Useful probes

```bash
pacman -Q pacman yay 2>&1 || true
pacman -Ql pacman | grep -E 'libalpm\.so' || true
yay --version
```

Also verify prerequisite build tools:

```bash
pacman -Q base-devel git fakeroot binutils gcc make pkgconf 2>&1 || true
command -v go gcc make git fakeroot makepkg pacman sudo
```

## Repair used

Rebuild `yay` from AUR with plain `git` + `makepkg` so it links against the current pacman/libalpm:

```bash
workdir=$(mktemp -d /tmp/yay-aur.XXXXXX)
git clone https://aur.archlinux.org/yay.git "$workdir/yay"
cd "$workdir/yay"
makepkg -f --noconfirm --cleanbuild
```

Preferred install, when sudo is available:

```bash
sudo pacman -U ./yay-*.pkg.tar.zst
```

User-local fallback used when sudo was unavailable in-session and `~/.local/bin` already shadowed `/usr/bin`:

```bash
mkdir -p "$HOME/.local/bin"
pkg=''
for p in ./*.pkg.tar.zst; do
  case "$p" in *-debug-*) continue ;; *) pkg="$p"; break ;; esac
done
bsdtar -xOf "$pkg" usr/bin/yay > "$HOME/.local/bin/yay"
chmod 0755 "$HOME/.local/bin/yay"
```

Important detail: `makepkg` produced both `yay-...pkg.tar.zst` and `yay-debug-...pkg.tar.zst`; a naive `./*.pkg.tar.*` extraction selected the debug package first and failed. Skip `*-debug-*` or explicitly choose the non-debug package.

## Verification performed

```bash
PATH="$HOME/.local/bin:$PATH"
command -v yay
yay --version
# expected shape: yay v... - libalpm v...

yay -Ss --aur --color never google-chrome

verify_dir=$(mktemp -d /tmp/aur-download-test.XXXXXX)
cd "$verify_dir"
yay -G --noconfirm yay >/dev/null
test -f yay/PKGBUILD
```

## User-facing explanation

If the helper is installed user-local instead of with `pacman -U`, explain that `/usr/bin/yay` may still be broken but is shadowed by `~/.local/bin/yay`. Offer the exact `sudo pacman -U <built-package>` command as the optional system-wide replacement.
