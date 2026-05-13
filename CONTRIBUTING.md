# Contributing

Forks should stay easy: most behavior lives in **plain files** (`packages/brew/Brewfile`, `packages/macos/defaults`, `home/`) and small **`packages/<name>/install`** scripts. The **`cli/`** TypeScript layer only orchestrates prompts and `spawn`s those scripts.

## Add a package

1. Create **`packages/<name>/install`** (executable shell or any `#!/usr/bin/env` shebang).
2. Optionally add **`packages/<name>/export`** for `./export.sh` / `dotfiles sync`.
3. Register the name in **`cli/src/index.ts`** in the `PACKAGES` array and keep install order consistent with [`bootstrap.sh`](bootstrap.sh) expectations (today: `brew` → `macos` → `home` → `sudo`).
4. Document new **environment variables** in [`README.md`](README.md) if the package reads any.

Out-of-tree packages: set **`DOTFILES_EXTRA_PACKAGES_DIRS`** (colon-separated roots that each contain `packages/<name>/install`). See [`packages/helpers/packages.sh`](packages/helpers/packages.sh).

## Run the CLI locally

```bash
export DOTFILES_ROOT="$PWD"   # repo root
cd cli && npm ci && npm run start -- --help
```

- **`npm run start -- install`** — default bootstrap flow (same as `./bootstrap.sh` after preflight).
- **`npm run start -- install --yes`** — non-interactive; respects **`DOTFILES_PACKAGES`** / **`DOTFILES_SKIP`**.
- **`npm run start -- sync`** — runs **`./export.sh`** (pass through extra args, e.g. `--timestamp`).

## Homebrew bundles

- **`packages/brew/Brewfile.bootstrap`** — minimal **`brew "node"`** for first-run CLI; applied by **`bootstrap.sh`** before `npm ci` if `node` is missing.
- **`DOTFILES_BREWFILES`** — comma-separated filenames under **`packages/brew/`** (default **`Brewfile`**). Example: `Brewfile,Brewfile.apps` if you split casks into a second file.

## Linux and other OS (future)

Today this repo targets **macOS** paths (e.g. Touch ID `sudo`, `scutil` hostname). For **Linux**:

- Keep shared dotfiles under **`home/.config`** where possible.
- Add **`packages/linux/<name>/install`** (or another layout you document) and extend **`dotfiles_find_package_script`** / the CLI `PACKAGES` list when you are ready to discover OS-specific steps — the important part is **one documented convention** so forks do not fork the orchestrator.

## CI / automation

Use **`./bootstrap.sh`** with **`DOTFILES_SKIP`** / **`DOTFILES_PACKAGES`** and/or run **`cli`** with **`install --yes`**. Do not rely on Clack when **`stdin` is not a TTY**.
