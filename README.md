# Dotfiles

Personal macOS dotfiles. Two entry points:

- **`./bootstrap.sh`** — preflights **Node** for the CLI, runs **`npm ci`** in **`cli/`**, then the **dotfiles CLI** (`citty` + `@clack/prompts`) drives **`packages/<name>/install`** (Homebrew bundles, macOS defaults, `home/` → `$HOME` via rsync, Touch ID for `sudo`).
- **`./export.sh`** — pulls live state back into the repo (same as before). You can also run **`npm run start -- sync`** from **`cli/`** (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## Quick start

[`./bootstrap.sh`](bootstrap.sh) must run from a checkout on disk. Do not pipe `bootstrap.sh` straight into `bash` from `curl`.

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

1. **Preflight** — If `node` is missing: install **Homebrew** if needed, then apply **`packages/brew/Brewfile.bootstrap`** (minimal `brew "node"`) or **`brew install node`** if the bootstrap file is absent.
2. **`npm ci`** in **`cli/`** — installs CLI dependencies (including `tsx`, `citty`, `@clack/prompts`).
3. **CLI `install`** — On a TTY, **Clack** asks which packages to run (default: all). Then runs each selected **`packages/<name>/install`** with **`stdio: 'inherit'`** in order **brew → macos → home → sudo**.

Use **`./bootstrap.sh --`** or pass flags through to the CLI: **`./bootstrap.sh -- install --yes`** for non-interactive installs.

### Brew bundles

- **`packages/brew/Brewfile`** — main formulae and casks (same as before).
- **`packages/brew/Brewfile.bootstrap`** — **only** `brew "node"` for first-run CLI; not applied again by the **`brew`** package step unless you list it in **`DOTFILES_BREWFILES`**.
- **`DOTFILES_BREWFILES`** — optional comma-separated basenames under **`packages/brew/`** (default **`Brewfile`**). Example: `Brewfile,Brewfile.apps` if you split heavy casks into a second file.
- **`Brewfile.local`** next to **`Brewfile`** is still applied automatically after the listed bundles.

## What `./export.sh` and `sync` do

Same as before: **`./export.sh`** refreshes **`packages/brew/Brewfile`**, rewrites **`packages/macos/defaults`**, snapshots curated **`$HOME`** files under **`exports/home/`**.

From the repo after `npm ci` in **`cli/`**:

```bash
DOTFILES_ROOT="$PWD" npm run start --prefix cli -- sync
DOTFILES_ROOT="$PWD" npm run start --prefix cli -- sync -- --timestamp
```

(`--` separates npm args from script args when using `npm run start`.)

## Where things live

- **`home/`** — Files copied into `$HOME` via **`packages/home/install`** (`rsync -a`; **`/usr/bin/rsync`** on macOS is enough).
- **`packages/<name>/`** — One directory per concern: executable **`install`** (and optional **`export`**), plus data files (e.g. **`packages/brew/Brewfile`**).
- **`cli/`** — TypeScript CLI: **`src/index.ts`**, **`package-lock.json`** committed for reproducible **`npm ci`**.
- **`packages/lib.sh`** + **`packages/helpers/`** — Shared shell helpers (filtering, brew, orchestration). Still sourced by package scripts.
- **`exports/`** — Output of the **`home`** export step.

## How `home/` is applied

`packages/home/install` runs `rsync` (see **`DOTFILES_RSYNC_DELETE`**). SSH perms and login shell behavior are unchanged.

## Personalization

Use **`~/.config/zsh/local.zsh`**, **`git config --global include.path …`**, **`Brewfile.local`**, and **`DOTFILES_SKIP`** / **`DOTFILES_PACKAGES`** so the wizard and scripts never fight intentional local divergence.

## Common environment knobs

- **`DOTFILES_REPO`** — For **`first-install.sh`**: GitHub `owner/repo` slug.
- **`GIT_REPO_URL`** — Full clone URL when `DOTFILES_REPO` is not enough.
- **`DOTFILES_CLONE_DIR`** — Clone destination (default `~/dotfiles`).
- **`DOTFILES_PACKAGES`** / **`DOTFILES_SKIP`** — Comma lists for install steps (skip wins). Set either (or use **`install --yes`**) to skip Clack in automation.
- **`DOTFILES_BREWFILES`** — Comma-separated brew bundle files under **`packages/brew/`** (default **`Brewfile`**).
- **`DOTFILES_RSYNC_DELETE`** — Passed to the **`home`** install step.
- **`DOTFILES_HOSTNAME`** — Passed through to **`macos`** install when set.

Full list: comments in [`bootstrap.sh`](bootstrap.sh), [`packages/lib.sh`](packages/lib.sh), and [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Commands

- **`./bootstrap.sh`** — Preflight Node → **`npm ci`** in **`cli/`** → interactive or non-interactive **`install`**.
- **`./bootstrap.sh -- install --yes`** — Non-interactive bootstrap (same env knobs as above).
- **`./export.sh`** — Refresh Brewfile, macOS defaults in place, snapshot curated home files under **`exports/home/`**.
- **`./export.sh --timestamp`** — Same, but timestamped export root for the **`home`** snapshot.
- **`npm run start --prefix cli -- sync`** — Wrapper around **`./export.sh`** (from repo root; set **`DOTFILES_ROOT`**).

## Contributing

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for adding packages, **`DOTFILES_EXTRA_PACKAGES_DIRS`**, and notes on future **Linux** / multi-OS layout.
