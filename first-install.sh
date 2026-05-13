#!/usr/bin/env bash
# first-install.sh - first machine only: clone (or reuse) a dotfiles repo on disk, then run bootstrap.
#
# Typical GitHub use (one slug — same value in raw.githubusercontent.com and github.com):
#   DOTFILES_REPO=owner/repo
#   curl -fsSL "https://raw.githubusercontent.com/${DOTFILES_REPO}/main/first-install.sh" \
#     | env DOTFILES_REPO="$DOTFILES_REPO" bash -s --
#
# Other remotes: set GIT_REPO_URL (HTTPS or SSH) instead of DOTFILES_REPO.
#
# Environment:
#   DOTFILES_REPO        Optional. GitHub slug owner/repo → clone https://github.com/owner/repo.git
#   GIT_REPO_URL         Optional. Full clone URL (wins over DOTFILES_REPO if both set).
#   DOTFILES_CLONE_DIR   Target directory (default: $HOME/dotfiles)
#
# Positional: if neither GIT_REPO_URL nor DOTFILES_REPO is set, the first argument may be a
# full clone URL, git@… URL, or owner/repo; it is consumed and remaining args go to bootstrap.

set -euo pipefail

clone_url=""
if [[ -n "${GIT_REPO_URL:-}" ]]; then
  clone_url="$GIT_REPO_URL"
elif [[ -n "${DOTFILES_REPO:-}" ]]; then
  if [[ "$DOTFILES_REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    clone_url="https://github.com/${DOTFILES_REPO}.git"
  else
    echo "first-install.sh: DOTFILES_REPO must look like owner/repo (got: ${DOTFILES_REPO})" >&2
    exit 1
  fi
elif [[ -n "${1:-}" ]]; then
  if [[ "$1" == *'://'* ]] || [[ "$1" == git@* ]]; then
    clone_url="$1"
    shift
  elif [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    clone_url="https://github.com/${1}.git"
    shift
  fi
fi

if [[ -z "$clone_url" ]]; then
  echo "first-install.sh: set DOTFILES_REPO=owner/repo for github.com, or GIT_REPO_URL, or pass a clone URL / owner/repo as the first argument after 'bash -s --'." >&2
  exit 1
fi

target="${DOTFILES_CLONE_DIR:-$HOME/dotfiles}"

if [[ ! -e "$target" ]]; then
  mkdir -p "$(dirname "$target")"
  git clone --depth 1 "$clone_url" "$target"
elif [[ -d "$target/.git" ]]; then
  git -C "$target" pull --ff-only 2>/dev/null || true
elif [[ -z "$(find "$target" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]]; then
  git clone --depth 1 "$clone_url" "$target"
else
  echo "Refusing to clone: $target exists and is not a git repository." >&2
  exit 1
fi

cd "$target"
exec ./bootstrap.sh "$@"
