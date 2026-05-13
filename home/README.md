# `home/`

This directory is the **source of truth** for paths that should exist under **`$HOME`**. Layout is a **single flat tree** (not per-app subfolders):

```text
home/
  .zshrc
  .gitconfig
  .gitignore_global
  .ssh/config
  .config/zsh/history.zsh
  .config/zsh/aliases.zsh
  README.md
```

`README.md` is repo-only; [`packages/home/install`](../packages/home/install) does not copy it into **`$HOME`**.

Install order and other environment variables are in the **[root `README.md`](../README.md)**.

## Export

To snapshot matching files **from** `$HOME` back into an export tree (for merging or backup), use **`./export.sh`**; the **`home`** export step is implemented as [`packages/home/export`](../packages/home/export) (git globals + `~/.ssh/config` only, never private keys).

## Personalization

Use normal config mechanisms (for example `~/.config/zsh/local.zsh`, git `[include]`) for machine-specific tweaks that you do not want in this repo.
