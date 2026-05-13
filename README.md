# Dotfiles

Personal macOS dotfiles. Two entry points:

- `./bootstrap.sh` applies this repo to the machine: Homebrew + Brewfile, macOS defaults, copies `home/` into `$HOME`, enables Touch ID for `sudo`.
- `./export.sh` pulls live state back into the repo: refreshes `packages/brew/Brewfile`, rewrites `packages/macos/defaults` in place, and copies a curated subset of `$HOME` into `exports/home/`.

## Quick start

[`./bootstrap.sh`](bootstrap.sh) must run from a checkout on disk (it loads `packages/lib.sh` next to the script). Do not pipe `bootstrap.sh` straight into `bash` from `curl`.

Already have the repo (any path):

```bash
cd /path/to/dotfiles && ./bootstrap.sh
```

Clone into `~/dotfiles` (change the path if you want). One variable keeps the GitHub slug in sync:

```bash
DOTFILES_REPO=fjcero/dotfiles
git clone "https://github.com/${DOTFILES_REPO}.git" ~/dotfiles && cd ~/dotfiles && ./bootstrap.sh
```

First-time one-liner: pipe only [`first-install.sh`](first-install.sh) (never `bootstrap.sh`). Use the same `DOTFILES_REPO` in the `curl` URL and in `env` so the script you download and the tree you clone always match. Default clone dir is `~/dotfiles` (`DOTFILES_CLONE_DIR` to override).

```bash
DOTFILES_REPO=fjcero/dotfiles
curl -fsSL "https://raw.githubusercontent.com/${DOTFILES_REPO}/main/first-install.sh" \
  | env DOTFILES_REPO="$DOTFILES_REPO" bash -s --
```

Non-GitHub or SSH remotes: set `GIT_REPO_URL` instead of `DOTFILES_REPO` (full clone URL); your `curl` URL should still point at the `first-install.sh` you trust (often the same repo's raw file). Piping `bash` trusts TLS and the host; use a pinned branch or tag in the URL if you care.

## What `./bootstrap.sh` does

In order:

1. **brew** — installs Homebrew if missing, then applies [`packages/brew/Brewfile`](packages/brew/Brewfile). A `Brewfile.local` next to it is also picked up if present.
2. **macos** — applies the `defaults write …` commands in [`packages/macos/defaults`](packages/macos/defaults). Optionally sets the hostname via `DOTFILES_HOSTNAME`.
3. **home** — rsyncs the tree under `home/` into `$HOME`, fixes `~/.ssh` perms, switches your login shell to zsh if needed.
4. **sudo** — enables Touch ID for `sudo` (prompts for your password once).

Each step is a script at `packages/<name>/install`. Filter with `DOTFILES_PACKAGES=...` (allow list) and `DOTFILES_SKIP=...` (deny list; skip wins over allow).

## What `./export.sh` does

1. **brew** — `brew bundle dump --force` over [`packages/brew/Brewfile`](packages/brew/Brewfile).
2. **macos** — rewrites values in [`packages/macos/defaults`](packages/macos/defaults) to match the current live system. Only existing keys are updated; lines are never added or removed.
3. **home** — copies a curated subset of `$HOME` into `exports/home/`: `.gitconfig`, `.gitignore_global`, and `.ssh/config`. **Private SSH keys are never copied.**

`./export.sh --timestamp` puts the `home` snapshot under `exports/<YYYYmmdd-HHMMSS>/home/`. The `brew` and `macos` exports always write in place; timestamping does not affect them.

## Where things live

- `home/` — Files copied verbatim into `$HOME`. Layout is a single flat tree (e.g. `home/.zshrc`, `home/.config/zsh/aliases.zsh`), not per-app subfolders.
- `packages/<name>/` — One directory per concern. Holds an executable `install` (and optional `export`) plus any small data files (e.g. [`brew/Brewfile`](packages/brew/Brewfile), [`macos/defaults`](packages/macos/defaults)).
- `packages/lib.sh` + `packages/helpers/` — Shared shell helpers organized by responsibility (filtering, package discovery, orchestration, I/O, brew). Loaded by entry scripts and package scripts.
- `exports/` — Where `./export.sh` writes the `home` snapshot. The `brew` and `macos` exports overwrite their in-repo source files directly.

## How `home/` is applied

`packages/home/install` runs `rsync -a home/ $HOME/`. It also `chmod 700`s `~/.ssh` and switches your login shell to zsh if it isn't already.

Set `DOTFILES_RSYNC_DELETE=1` to pass `--delete` to rsync. That removes files in `$HOME` that no longer exist in `home/` — risky; only enable if you understand the consequences.

## Personalization

For machine-specific tweaks you don't want in the repo, use the normal config-include mechanisms: `~/.config/zsh/local.zsh`, `git config --global include.path …`, or a `Brewfile.local` next to [`packages/brew/Brewfile`](packages/brew/Brewfile) (picked up automatically by `packages/brew/install`).

## Common environment knobs

- `DOTFILES_REPO` — For [`first-install.sh`](first-install.sh): GitHub `owner/repo` slug; expands to `https://github.com/owner/repo.git`. Use the same value in `raw.githubusercontent.com/…/first-install.sh` and in `env` so curl and clone stay aligned. This README uses `fjcero/dotfiles` in the examples.
- `GIT_REPO_URL` — Full clone URL when `DOTFILES_REPO` is not enough (non-`github.com` HTTPS, SSH, etc.). If set, it overrides `DOTFILES_REPO`.
- `DOTFILES_CLONE_DIR` — Where `first-install.sh` puts the clone (default `~/dotfiles`).
- `DOTFILES_PACKAGES` / `DOTFILES_SKIP` — Comma lists to allow or skip install steps (skip wins).
- `DOTFILES_RSYNC_DELETE` — Passed through to the `home` install step; see [How `home/` is applied](#how-home-is-applied).

Full list: comments in [`bootstrap.sh`](bootstrap.sh) and [`packages/lib.sh`](packages/lib.sh).

## Commands

| Command                                  | Purpose                                                                                                                                              |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `./bootstrap.sh`                         | Homebrew + Brewfile, macOS defaults, apply `home/` into `$HOME`, enable Touch ID for `sudo`.                                                         |
| `./export.sh`                            | Refresh [`packages/brew/Brewfile`](packages/brew/Brewfile), rewrite [`packages/macos/defaults`](packages/macos/defaults) in place, snapshot a subset of `$HOME` under `exports/home/`. |
| `./export.sh --timestamp`                | Same, but the `home` snapshot goes under `exports/<YYYYmmdd-HHMMSS>/home/`. `brew` and `macos` still rewrite their in-repo files.                    |
| `./packages/macos/export --output <dir>` | Rewrite `<dir>/defaults` with the live values of every key in [`packages/macos/defaults`](packages/macos/defaults). Standalone variant of the macOS export step. |
