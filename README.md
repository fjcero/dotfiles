# Dotfiles

Composable machine setup: **`bootstrap.sh`** runs Homebrew, macOS defaults (when enabled), the **`home`** package (apply dotfiles + small post-steps), and optional system packages. **`export.sh`** snapshots **`brew`**, **`macos`**, and **`home`** into **`exports/<package>/`** (see below).

## Mental model

- **`home/`** — Your real dotfiles as they should appear under **`$HOME`** (a single tree: `.zshrc`, `.gitconfig`, `.ssh/config`, `.config/...`). Everything you care to version for the shell and apps lives here.
- **`packages/`** — Scripts that **run** on bootstrap or export: **`brew/`** (install + **`Brewfile`** + export), **`macos/`**, **`home/`** (apply dotfiles + small post-steps + export snapshots from `$HOME`), optional **`sudo/`** and **`hosts/`** for system setup, plus **`lib.sh`**.

## Bootstrap

Rough flow:

1. **Homebrew** — Ensure `brew` is available, then **`brew bundle`** using **[`packages/brew/Brewfile`](packages/brew/Brewfile)**. The Brewfile is a machine recipe kept next to the brew install script; it is not something that needs to live as `~/Brewfile`.
2. **macOS defaults** — When the **`macos`** package runs, curated **`defaults write`** settings from [`packages/macos/install`](packages/macos/install).
3. **`home` package** — Applies the repo’s **`home/`** tree into **`$HOME`** (**`rsync`** by default, or **`stow`**). **`README.md`** and **`.stow-local-ignore`** are not copied into `$HOME`. Then **`chmod 700 ~/.ssh`** when `~/.ssh` exists, and a best-effort **zinit compile** if zinit is present.
4. **System (optional)** — **`sudo`** and **`hosts`** when **`DOTFILES_SYSTEM=1`**.

Default install order: **`brew` → `macos` → `home`** (see **`dotfiles_run_installs`** in [`packages/lib.sh`](packages/lib.sh)). Use **`DOTFILES_PACKAGES`** / **`DOTFILES_SKIP`** to narrow what runs.

**`export.sh`** writes **`exports/<package>/`** for **`brew`**, **`macos`**, and **`home`** (the **`home`** export snapshots **`~/.gitconfig`**, **`~/.gitignore_global`**, and **`~/.ssh/config`** from the machine, not private keys).

Personalization stays in normal config files (e.g. git includes, `~/.config/zsh/local.zsh`), not a separate overrides tree in this repo.

## Applying `home/` (`DOTFILES_HOME_MODE`)

| Mode | Behavior |
|------|----------|
| **`rsync`** (default) | `rsync -a` from `home/` to `$HOME/`, with **`--exclude=README.md`** and **`--exclude=.stow-local-ignore`**. Overwrites matching paths; **no** `--delete` unless **`DOTFILES_RSYNC_DELETE=1`**. |
| **`stow`** | GNU Stow: symlinks from the repo into `$HOME`. Set **`DOTFILES_HOME_MODE=stow`**. |

## Layout

| Path | Role |
|------|------|
| `home/` | Mirror of paths under `$HOME` (dotfiles source of truth). |
| `packages/lib.sh` | Shared helpers, allow/skip lists, install/export runners. |
| `packages/<name>/install` | Bootstrap step (only **`brew`**, **`macos`**, **`home`**, plus optional **`sudo`** / **`hosts`** with `DOTFILES_SYSTEM=1`). |
| `packages/<name>/export` | Export step (**`brew`**, **`macos`**, **`home`**). |
| `packages/brew/Brewfile` | Declarative brew bundle list; consumed by `packages/brew/install`. |

## Environment

| Variable | Effect |
|----------|--------|
| `DOTFILES_HOME_MODE` | How to apply `home/`: **`rsync`** (default) or **`stow`**. |
| `DOTFILES_RSYNC_DELETE` | If `1` while mode is `rsync`, rsync runs with **`--delete`**. |
| `DOTFILES_PACKAGES` | Comma allow list for **install** (if unset, default order runs). |
| `DOTFILES_SKIP` | Comma deny list; **skip wins** over allow. |
| `DOTFILES_SYSTEM=1` | Run privileged **`packages/sudo/install`** and **`packages/hosts/install`**. |
| `DOTFILES_EXTRA_PACKAGES_DIRS` | Colon-separated extra repo roots containing `packages/<name>/…`. |
| `DOTFILES_EXPORT_ROOT` | Base directory for exports (default: `./exports`). |
| `DOTFILES_EXPORT_PACKAGES` | Allow list for **export** (defaults to `DOTFILES_PACKAGES` when unset). |
| `DOTFILES_EXPORT_SKIP` | Deny list for export (defaults to `DOTFILES_SKIP` when unset). |

## Commands

```bash
./bootstrap.sh
./export.sh
./export.sh --timestamp
./packages/macos/export --list
```

See [`home/README.md`](home/README.md) for how this tree relates to `$HOME` and for personalization notes.
