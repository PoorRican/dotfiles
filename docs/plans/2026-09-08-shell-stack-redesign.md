# Shell Stack Redesign: zsh + starship + helix-mode under Home Manager

Status: proposal for review. Nothing in this document has been implemented.

## Objective

Replace the oh-my-zsh based interactive shell with a Home Manager-native
configuration that provides:

- a `starship` prompt with `jj-starship` as the VCS segment;
- Helix/Kakoune-style modal line editing instead of `vi-mode`;
- shell plugins chosen against the toolchains actually present in `~/repos`;
- CLI completions delivered by the flake, with no manual commands;
- the oh-my-zsh `git` aliases preserved exactly;
- a MOTD and banner that are cheaper and cleaner than the current ones.

The last section evaluates whether a different login shell would buy anything.

Section 9 lists every decision the reviewer must make. Each option is labelled
so a reply of the form `D1: A, D2: B, ...` is sufficient to start
implementation.

## 1. Current state (verified 2026-09-08 on cbox)

Sources: `configs/zsh/zshrc`, `configs/zsh/zshenv`, `configs/zsh/modules/*`,
`nix/modules/zsh.nix`, `nix/profiles/shell.nix`.

| Concern | Today | Problem |
|---|---|---|
| Delivery | `zsh.nix` symlinks hand-written `.zshrc`/`.zshenv`; `~/.zsh/*.zsh` glob-sourced | `programs.*.enableZshIntegration` hooks have nowhere to land; ordering is filename-based |
| Framework | oh-my-zsh from nixpkgs, `plugins=(git pip python vi-mode colored-man-pages cp extract)` + `brew macos` on Darwin | Framework loads themes/lib/async machinery to get ~200 aliases |
| Prompt | `05-prompt.zsh` (xero ascii style) with synchronous `git status`/`name-rev`/`diff` per prompt | Three git subprocesses per prompt; no jj support |
| Modal editing | OMZ `vi-mode` | Vim keys, not selection-first |
| Banner | `00-logo.zsh` picks "randomly" between two identical banners, runs `clear` on every shell | Runs in every zellij/tmux pane; `clear` discards scrollback |
| MOTD | `01-motd.zsh` shells out to `uptime`, `last`, `date` | Unstyled, duplicates hostname line |
| Completions | OMZ `compinit` + hand-added `fpath` from two profile paths; `fpath=(~/.zfunc ...)` | `~/.zfunc` does not exist on cbox (dead code) |
| Startup | 60-80 ms (`zsh -i -c exit`, warm) | Baseline to hold |

Completions currently present in the profile (`share/zsh/site-functions`):
bat bun cargo fd gh git-lfs home-manager hx jj lefthook luarocks pixi rclone
rg ruff rustup taplo tombi uv yazi zellij. Provided by zsh itself: git tmux ssh
jq npm mosh sqlite. Missing on cbox: docker (`/usr/bin/docker`, OS-installed),
kubectl (`~/.local/bin`), direnv (ships none), cmake, node, nvim, psql,
pre-commit. Not importable on cbox (`dev-cloud` profile absent): aws gcloud
pulumi ngrok.

## 2. Repository survey (`~/repos`, 50 units)

Full report: `agent://RepoToolchainScout`.

- VCS: git 44, jj 0, none 4.
- Language: Python ~22, Rust ~16, TypeScript 6, Lua 1, shell/ops 3.
- Package managers: uv 16, cargo 16, bun 3, pip 3, npm 3, pnpm 1.
- Containers: docker-compose 11, Dockerfile 3, podman quadlet 1.
- Nix + direnv: 1 (`enhanced-hermes-ui-tui`, `use flake`).
- Hooks: pre-commit 4, cargo-husky 3, lefthook 0.
- Absent everywhere: k8s/helm/pulumi/terraform, just/make/task/mise, marimo,
  zenml, dvc.

Implication: completion priority is git/gh, uv, cargo/rustup, docker compose,
bun, ruff, pre-commit. jj has zero repos today but is a stated requirement, so
the jj prompt segment must be free when not in a jj repo (see 3.1).

## 3. Proposed design

### 3.0 Module layout

```
nix/modules/zsh.nix          rewritten: programs.zsh.*, plugins, initContent ordering
nix/modules/starship.nix     new: programs.starship + jj-starship package + config file
nix/modules/motd.nix         new: programs.fastfetch + build-time banner derivation
nix/modules/lib/mk-completion.nix
                             new: package that writes share/zsh/site-functions/_<tool>
                             from `<tool> completion zsh` at build time
configs/zsh/modules/         keep: 00-term, 04-exit-bell, 99-utils, sourcerer
                             add:  git-helpers.zsh (12 lines, see 3.5)
                             delete: 00-logo, 01-motd, 05-prompt
configs/starship/starship.toml   new
configs/zsh/zshrc, zshenv    delete (content migrates into programs.zsh options)
```

`profiles/shell.nix` imports `zsh.nix`, `starship.nix`, `motd.nix`. All five
hosts import `shell.nix`, so anything Linux-only is gated with
`lib.mkIf pkgs.stdenv.isLinux`.

Home Manager owns `.zshenv` and `.zshrc`. Its generated `.zshenv` already
sources `hm-session-vars.sh` and sets PATH, which replaces `zshrc:12-26`. The
XDG and Nix bootstrap from `configs/zsh/zshenv` moves verbatim into
`programs.zsh.envExtra`. The OMZ block (`zshrc:37-139`) is deleted.

Ordering matters. Home Manager's generated zshrc places (from
`modules/programs/zsh/default.nix` at the locked revision
`f404edbf`):

| Order | Content |
|---|---|
| 520 | `fpath += $profile/share/zsh/site-functions` for every `$NIX_PROFILES` entry |
| 530 | `defaultKeymap` bindkey |
| 560 | plugin dirs added to `fpath` |
| 570 | `compinit` |
| 700 | zsh-autosuggestions |
| 851 | zoxide init |
| 900 | `programs.zsh.plugins` sourced |
| 910 | fzf integration |
| 1000 | plain `initContent` |
| 1100 | `shellAliases` |
| 1200 | zsh-syntax-highlighting |

Consequences: any custom `fpath` entry must be a package with
`share/zsh/site-functions` (picked up at 520) or be placed with
`lib.mkOrder` below 570; anything that must run after syntax highlighting
(the helix-mode highlight hook) goes at 1250.

### 3.1 Prompt: starship + jj-starship

- `programs.starship.enable = true`, `settings` left empty, config file
  provided from `configs/starship/starship.toml` (matches repo convention of
  checked-in config files).
- `pkgs.jj-starship` 0.7.1 (nixpkgs; upstream `dmmulroy/jj-starship`, verified
  via `meta.homepage`). Built and run in this repo:

  ```
  $ jj-starship --no-color
  on  master (86abc608) [!?]
  $ jj-starship detect; echo $?
  0
  ```

  Binary name is `jj-starship`; no config file required. `nixpkgs.starship-jj`
  is a different project (gitlab lanastara) and is not used.
- Starship block:

  ```toml
  [git_branch]
  disabled = true
  [git_status]
  disabled = true
  [custom.jj]
  when = "jj-starship detect"
  shell = ["jj-starship"]
  format = "$output "
  ```

  `detect` walks up for `.jj` or `.git`, so this is one subprocess per prompt
  for both VCSs and nothing outside a repo.
- Modules enabled: `directory`, `custom.jj`, `python` (uv venvs), `rust`,
  `nix_shell`, `direnv`, `hostname` (ssh only), `cmd_duration`, `status`
  (pairs with the exit bell), `character`. All other language scanners
  disabled; each costs a directory walk per prompt.
- Visual: reproduce the current xero "ascii" style (cyan directory block,
  magenta VCS block, `▓▒░` transitions, input on line two) using the sourcerer
  palette from `configs/ghostty/themes/sourcerer`.
- Known gap: starship's `character` vi-mode indicator reads `$KEYMAP` and does
  not track helix keymaps. Mode indication comes from cursor shape/color, which
  zsh-helix-mode emits (3.2).

### 3.2 Modal editing: zsh-helix-mode

`Multirious/zsh-helix-mode` (MIT, 111 stars, 9 open issues; HEAD of `main`
on 2026-09-08: `e8d4940588f9809ab5658aa7c9c664921d547879`). Not in nixpkgs
26.05 (probed: MISSING). Implements Helix normal/select/insert modes, match,
goto, multi-cursor, registers, undo with selection history, multi-line via
Alt-Enter, and per-mode cursor escape sequences.

Integration requirements from its README, mapped to Home Manager orders:

| Requirement | Placement |
|---|---|
| Source before zsh-syntax-highlighting | `programs.zsh.plugins` (900) < highlighting (1200) |
| `zhm-add-update-region-highlight-hook` after highlighting | `initContent` at `mkOrder 1250` |
| autosuggestions widget lists (`ZSH_AUTOSUGGEST_{CLEAR,ACCEPT,PARTIAL_ACCEPT}_WIDGETS`) | `initContent` at 1000 |
| fzf-tab wrap: `zhm_wrap_widget fzf-tab-complete zhm_fzf_tab_complete; bindkey '^I' zhm_fzf_tab_complete` | `initContent` at 1250 |
| Cursor colors `ZHM_CURSOR_{NORMAL,SELECT,INSERT}` | set to sourcerer palette in `localVariables` |
| Clipboard: defaults to `wl-copy`/`xclip` by `$WAYLAND_DISPLAY`/`$DISPLAY` | already installed on cbox; no-op on servers |

Fallback if the plugin proves rough in daily use: `pkgs.zsh-vi-mode` 0.12.0
via `programs.zsh.plugins` with the same ordering, vim keys.

Known issue from upstream: partial accept via `w`/`e` leaves one character of
the autosuggestion unaccepted.

### 3.3 Plugins

Recommended (all in nixpkgs 26.05 unless noted):

| Plugin | Why | Mechanism |
|---|---|---|
| zsh-autosuggestions 0.7.1 | history-driven inline suggestions | `programs.zsh.autosuggestion.enable` |
| zsh-syntax-highlighting 0.8.0 | command validity while typing | `programs.zsh.syntaxHighlighting.enable` |
| fzf 0.72 + zsh-fzf-tab 1.3.0 | fuzzy `<TAB>` menu (replaces `menu select`), Ctrl-T / Alt-C | `programs.fzf.enable` + `plugins` |
| zoxide 0.9.9 | `z kairos` across 39 top-level repos | `programs.zoxide.enable` (init at 851) |
| direnv + nix-direnv 3.1.2 | replaces hand `eval "$(direnv hook zsh)"`; caches `use flake` devshells | `programs.direnv.{enable,nix-direnv.enable}` |
| zsh-completions 0.35.0 | long-tail completions (cmake, node tooling) | package on `home.packages` (site-functions at 520) |

Evaluated and not recommended:

- `zsh-forgit`: its `ga`/`gd`/`glo` shadow OMZ git aliases.
- `zsh-nix-shell`: one repo uses nix devshells; nix-direnv covers it.
- `zsh-history-substring-search`: helix-mode binds Ctrl-P/Ctrl-N for history.
- `atuin` 18.15: the real upgrade for five hosts (self-hostable sync on
  cbox/emc), but its Ctrl-R binding must be checked against helix insert-mode
  keys. Deferred to a follow-up.

Startup budget: hold under 120 ms (`zsh -i -c exit`, median of 5, warm);
drop fzf-tab first if exceeded.

### 3.4 Completions via the flake

Mechanism: every package on `home.packages` that ships
`share/zsh/site-functions/_<tool>` is on `fpath` before `compinit` with zero
configuration (order 520). This already covers the list in section 1.

Gaps and how each is closed:

| Tool | Today | Proposal |
|---|---|---|
| docker | `/usr/bin/docker`, no completion | `pkgs.docker-client` 29.7.2 ships `_docker` (verified); add the package Linux-only, or carapace (D2) |
| kubectl | `~/.local/bin`, no completion | `pkgs.kubectl` 1.36.3 + `mk-completion` (`kubectl completion zsh`), Linux-only, or carapace (D2) |
| pre-commit | absent | `pkgs.pre-commit` 4.5.1 + `mk-completion`; not covered by carapace |
| direnv | ships none | carapace only |
| aws / gcloud / pulumi | mbp `dev-cloud` profile; unverified | verify on mbp; carapace covers all three |
| claude / codex / omp | curl/bun installed, ship none | remain uncovered |
| jj | `_jj` present | nothing to do |

`carapace` 1.6.3 (nixpkgs) has 729 specs including aws cargo direnv docker
gcloud gh git jj kubectl nix pixi pulumi; it does not cover pre-commit, uv,
ruff, home-manager. Home Manager's `programs.carapace.enableZshIntegration`
sources `_carapace zsh`, which overrides native completions unless excluded
per command with `CARAPACE_EXCLUDES`.

`lib/mk-completion.nix` contract: `mkCompletion { pkg; binary ? pkg.pname;
args ? [ "completion" "zsh" ]; }` returns a `runCommand` derivation writing
`$out/share/zsh/site-functions/_<binary>` by running the binary at build time.
Nothing runs at activation.

Darwin note: `pkgs.docker-client` evaluates on `aarch64-darwin` (probed:
`docker-29.7.2` on mbp), but the user runs Docker Desktop's binary there, so
the generated completions are still gated Linux-only to avoid a closure the
host does not use.

### 3.5 Git aliases (requirement: preserved exactly)

Source of truth: `$oh-my-zsh/share/oh-my-zsh/plugins/git/git.plugin.zsh`
(nixpkgs `oh-my-zsh-2026-02-19`, 431 lines, 197 `alias` lines, 17 functions,
10 `compdef`). This file is NOT in this repo today; it is loaded by
`zshrc:132`.

Coupling audit of the plugin file (grep for `$ZSH`, `ZSH_CUSTOM`, `omz_`,
`zstyle :omz`, `git_*`):

- No `$ZSH`/`ZSH_CUSTOM`/`_omz_` references.
- Defines its own `git_main_branch`, `git_develop_branch`, `git_log_prettily`.
- Autoloads `is-at-least` itself (line 2).
- Requires `git_current_branch` (14 call sites), defined only in
  `lib/git.zsh`.

`lib/git.zsh` must NOT be sourced standalone: lines 147-198 take the async
branch on zsh >= 5.0.6 and call `_omz_register_handler`, defined only in
`lib/async_prompt.zsh`, which `oh-my-zsh.sh` loads. Sourcing it without the
framework produces `command not found` on every shell start.

Port:

1. Keep `pkgs.oh-my-zsh` as a plain package (nixpkgs keeps the alias set
   current). Do not set `ZSH`, do not source `oh-my-zsh.sh`.
2. Add `configs/zsh/modules/git-helpers.zsh` containing exactly
   `__git_prompt_git` and `git_current_branch` from `lib/git.zsh`
   (12 lines, copied verbatim).
3. Source `git-helpers.zsh` then `plugins/git/git.plugin.zsh` via
   `programs.zsh.plugins` (order 900, after `compinit` so the plugin's
   `compdef` calls succeed).
4. Move `goo`, `uh`, `uhh`, `zshcon` to `programs.zsh.shellAliases`.
5. Alias completion (`gco <TAB>` offering branches) continues to work because
   zsh expands aliases before completion.

Other plugins on `zshrc:132`, each audited the same way:

| Plugin | Size | Coupling | Disposition |
|---|---|---|---|
| `vi-mode` | 174 lines, 7 funcs | none | replaced by zsh-helix-mode (3.2) |
| `extract` | 145 lines, `x` alias, own `_extract` | none | source standalone; add plugin dir to `completions` |
| `cp` | 4 lines, `cpv` | none | source standalone |
| `colored-man-pages` | 54 lines | needs `autoload colors`; uses `${0:A:h}/nroff` | source standalone after `colors`, or replace with `MANPAGER=bat` (D4) |
| `pip` | 7 aliases, 4 funcs | none | drop or keep (D5); uv-era leftover |
| `python` | 3 aliases, 4 funcs | none | drop or keep (D5) |
| `brew` (Darwin) | 36 aliases | none | source standalone under `mkIf isDarwin` |
| `macos` (Darwin) | 2 aliases, 17 funcs | internal `_omz_macos_get_frontmost_app` only | source standalone under `mkIf isDarwin` |

Acceptance proof: dump `alias` and `functions` from a current shell before
cutover and from the new shell after; `diff` must show only the deliberate
removals listed above (`vi-mode` widgets, prompt functions, and whichever of
D4/D5 are dropped).

### 3.6 MOTD and banner

Replace `00-logo.zsh` and `01-motd.zsh` with `programs.fastfetch`
(nixpkgs 2.63.1):

- Logo: `assets/banners/pr_banner-stylized.txt` as a `file-raw` logo, which
  preserves its ANSI colors. The two banner variants in `00-logo.zsh` are
  byte-identical, so nothing is lost.
- Host name: a `runCommand` derivation renders `toilet -f rustofat
  <hostname>` from `assets/figlet/` at build time; the shell only `cat`s the
  result. These fonts are currently unused.
- Info block: host, uptime, load, memory, disk, local IP, plus last login via
  a fastfetch `command` module (`last -1 $USER`), keeping the information the
  current MOTD shows.
- No `clear`. Gating per D3.
- Bonus: `programs.jujutsu.settings` carries `user.name`/`user.email` from
  the same nix values as `configs/git/config`, so jj is ready when the first
  jj repo appears.

### 3.7 Another shell (lowest priority)

Fish 4.7.1: best default completions (man-page parsing plus bundled docker
and kubectl), built-in autosuggest and highlighting, abbreviations that
expand in history, `plugin-git` reproducing the OMZ aliases as abbrs. Starship,
jj-starship, fastfetch, fzf, zoxide carry over unchanged. Costs: no helix
mode (vi bindings only), the 17 OMZ git helper functions and `w`/`extract`
need porting, non-POSIX syntax for the existing `bin/` scripts' interactive
use.

Nushell 0.112.2: a data language rather than a shell swap; `open x.parquet |
where ...` with the polars plugin is useful for the ML repos, but completions
route through the carapace bridge and there is no helix mode. Better installed
as a tool than adopted as the login shell.

Verdict: stay on zsh. The condition that flips it is zsh-helix-mode being
unusable, in which case fish is the next stop.

## 4. Decisions required

Reply with the option letter per item.

**D1. zsh-helix-mode pin**

- A (recommended): `pkgs.fetchFromGitHub` inside `nix/modules/zsh.nix`
  pinned to `e8d4940588f9809ab5658aa7c9c664921d547879`. No `flake.nix`
  change; bump by editing rev/hash. Consistent with the repo rule against
  editing flake structure.
- B: flake input `zsh-helix-mode` with `inputs.nixpkgs.follows`. Updates via
  `nix flake lock --update-input zsh-helix-mode`; touches `flake.nix`.

**D2. Completions for tools not on the nix profile (docker, kubectl,
pre-commit, direnv, cloud CLIs)**

- A (recommended): nix-generated completions via `mk-completion.nix`
  (docker-client, kubectl, pre-commit), Linux-gated. Deterministic, no
  activation steps, native completion quality. Leaves direnv uncovered.
- B: `programs.carapace` bridge. Covers docker, kubectl, direnv, aws, gcloud,
  pulumi in one package; overrides native completions unless excluded per
  command; does not cover pre-commit, uv, ruff.
- C: both, with carapace excluded for every tool that ships native
  completions.

**D3. MOTD frequency**

- A (recommended): show only in top-level interactive shells (skip when
  `$ZELLIJ` or `$TMUX` is set). Every zellij pane currently renders the
  banner and clears.
- B: every interactive shell, as today, minus `clear`.

**D4. Man page coloring**

- A (recommended): `MANPAGER="sh -c 'col -bx | bat -l man -p'"`; bat is
  already installed.
- B: keep OMZ `colored-man-pages` sourced standalone.

**D5. `pip` and `python` OMZ plugins**

- A (recommended): drop; every Python repo in the survey is uv-managed.
- B: keep both sourced standalone (10 aliases, 8 functions).

**D6. Prompt style**

- A (recommended): reproduce the current xero "ascii" two-line layout in the
  sourcerer palette.
- B: a starship preset (e.g. plain or gruvbox-rainbow powerline) as a fresh
  start; the jj-starship README documents the powerline wiring.

**D7. jj identity**

- A (recommended): add `programs.jujutsu.settings.user` now.
- B: leave jj unconfigured until the first jj repo.

## 5. Verification plan

1. `nix eval '.#homeConfigurations.<host>.activationPackage' --no-build` for
   mbp, dgx, emc, cbox, wst.
2. `home-manager switch --flake .#cbox --dry-run` produces no errors
   (activation is currently blocked by unrelated `~/.claude/skills` and
   `~/.hermes/skills` link collisions; see memory).
3. Alias/function diff per 3.5.
4. Startup: median of 5 `zsh -i -c exit` under 120 ms; report the number.
5. Interactive smoke in a real pty: helix normal/select/insert transitions
   with cursor change, `gco <TAB>` offers branches, `docker <TAB>` completes
   subcommands, `z <name>` jumps, prompt shows jj-starship output inside this
   repo and nothing outside a repo.
6. MOTD renders once in a fresh terminal and not inside a zellij pane (if D3
   = A).

## 6. Out of scope

- Changing `flake.nix` inputs other than as decided in D1.
- Hyprland/i3/zellij configuration.
- atuin history sync (deferred; see 3.3).
- Porting `bin/` scripts to another shell.

## Appendix: evidence commands

```
nix eval --raw '.#homeConfigurations.cbox.pkgs.<attr>.name'      # package probes
nix build --no-link --print-out-paths '.#homeConfigurations.cbox.pkgs.jj-starship'
ls ~/.local/state/nix/profiles/home-manager/home-path/share/zsh/site-functions
grep -nE '_omz_register_handler|async-prompt' $OMZ/lib/git.zsh
grep -oE '\$ZSH\b|ZSH_CUSTOM|_omz_[a-z_]+|git_[a-z_]+' $OMZ/plugins/git/git.plugin.zsh | sort -u
carapace --list | jq -r 'keys[]'
grep -n 'mkOrder' <home-manager>/modules/programs/zsh/default.nix
```
