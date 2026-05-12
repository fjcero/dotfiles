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
  .stow-local-ignore
  README.md
```

`README.md` and `.stow-local-ignore` are repo metadata only; they are not synced into `$HOME` when using **rsync**, and Stow ignores them via `.stow-local-ignore`.

How files are applied (**`rsync` by default** vs optional **`stow`**), environment variables, and bootstrap order are documented in the **[root `README.md`](../README.md)**.

## Export

To snapshot matching files **from** `$HOME` back into an export tree (for merging or backup), use **`./export.sh`**; the **`home`** export step is implemented as [`packages/home/export`](../packages/home/export) (git globals + `~/.ssh/config` only, never private keys).

## Personalization

Use normal config mechanisms (for example `~/.config/zsh/local.zsh`, git `[include]`) for machine-specific tweaks that you do not want in this repo.
