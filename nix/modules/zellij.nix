# Zellij terminal multiplexer
{ pkgs, lib, dotfiles, ... }:
{
  home.packages = [ pkgs.zellij ];

  # Pre-grant plugin permissions so the (unfocusable) y/n prompt never appears.
  # Keys must exactly match the plugin URLs in configs/zellij/{config.kdl,layouts/*.kdl};
  # update them together when bumping plugin versions.
  home.activation.zellijPluginPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cache_dir=${
      if pkgs.stdenv.isDarwin
      then ''"$HOME/Library/Caches/org.Zellij-Contributors.Zellij"''
      else ''"''${XDG_CACHE_HOME:-$HOME/.cache}/zellij"''
    }
    perms="$cache_dir/permissions.kdl"
    run mkdir -p "$cache_dir"
    grant() {
      local url="$1"; shift
      if [ ! -f "$perms" ] || ! grep -qF "$url" "$perms"; then
        {
          printf '"%s" {\n' "$url"
          for p in "$@"; do printf '    %s\n' "$p"; done
          printf '}\n'
        } | run --quiet tee -a "$perms"
        verboseEcho "Granted zellij permissions for $url"
      fi
    }
    grant "https://github.com/dj95/zjstatus/releases/download/v0.24.0/zjstatus.wasm" \
      ReadApplicationState ChangeApplicationState RunCommands
    grant "https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm" \
      ReadApplicationState MessageAndLaunchOtherPlugins
  '';

  xdg.configFile."zellij/config.kdl".source = dotfiles + "/configs/zellij/config.kdl";
  xdg.configFile."zellij/layouts/sourcerer-layout.kdl".source = dotfiles + "/configs/zellij/layouts/sourcerer-layout.kdl";
  xdg.configFile."zellij/layouts/pk-wiki.kdl".source = dotfiles + "/configs/zellij/layouts/pk-wiki.kdl";
  xdg.configFile."zellij/layouts/sysadmin.kdl".source = dotfiles + "/configs/zellij/layouts/sysadmin.kdl";
}
