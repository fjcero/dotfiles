#!/usr/bin/env bash
# first-install.sh - first machine only: clone (or reuse) repo on disk, then run bootstrap.
#
# Intended for: curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/HEAD/first-install.sh | env GIT_REPO_URL='https://github.com/<org>/<repo>.git' bash -s -- [bootstrap args...]
#
# Environment:
#   GIT_REPO_URL         Required. e.g. https://github.com/you/dotfiles.git
#   DOTFILES_CLONE_DIR   Target directory (default: $HOME/dotfiles)

set -euo pipefail

if [[ -z "${GIT_REPO_URL:-}" ]]; then
  echo "Set GIT_REPO_URL to your dotfiles git clone URL (HTTPS or SSH)." >&2
  exit 1
fi

target="${DOTFILES_CLONE_DIR:-$HOME/dotfiles}"

if [[ ! -e "$target" ]]; then
  mkdir -p "$(dirname "$target")"
  git clone --depth 1 "$GIT_REPO_URL" "$target"
elif [[ -d "$target/.git" ]]; then
  git -C "$target" pull --ff-only 2>/dev/null || true
elif [[ -z "$(find "$target" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]]; then
  git clone --depth 1 "$GIT_REPO_URL" "$target"
else
  echo "Refusing to clone: $target exists and is not a git repository." >&2
  exit 1
fi

cd "$target"
exec ./bootstrap.sh "$@"
