# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"

if [[ -z "$XDG_RUNTIME_DIR" ]]; then
  export XDG_RUNTIME_DIR="/tmp/xdg-runtime-$(id -u)"
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
fi

# Cargo/Rust
if [ -e "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# Nix (single-user and multi-user installs)
for nix_profile in \
  "$HOME/.nix-profile/etc/profile.d/nix.sh" \
  "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" \
  "/etc/profile.d/nix.sh"
do
  if [ -e "$nix_profile" ]; then
    . "$nix_profile"
    break
  fi
done
