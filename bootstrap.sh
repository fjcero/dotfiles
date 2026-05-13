#!/usr/bin/env bash
# bootstrap.sh — apply this dotfiles repo to the current machine.
#
# Usage:
#   ./bootstrap.sh
#
# Flow: preflight Node (for the TypeScript CLI) → npm ci in cli/ → dotfiles install (citty + @clack/prompts)
#       → packages/*/install (brew, macos, home, sudo by default).
#
# Optional environment:
#   DOTFILES_PACKAGES      Comma-separated allow list (e.g. brew,home,macos).
#   DOTFILES_SKIP          Comma-separated deny list (skip wins over allow).
#   DOTFILES_HOSTNAME      Set machine hostname via scutil (requires sudo).
#   DOTFILES_RSYNC_DELETE  If 1, home install rsync uses --delete toward $HOME (use with care).
#   DOTFILES_BREWFILES     Comma-separated brew bundle files under packages/brew/ (default: Brewfile).

set -euo pipefail

export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=packages/lib.sh
source "$DOTFILES_ROOT/packages/lib.sh"

dotfiles_require_root || exit 1

echo "Bootstrapping from: $DOTFILES_ROOT"

preflight_node_for_cli() {
  if command -v node >/dev/null 2>&1; then
    return 0
  fi
  echo "==> preflight: Node not found; installing minimal toolchain for dotfiles CLI..."
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  ensure_brew_shellenv
  local bootstrap_file="$DOTFILES_ROOT/packages/brew/Brewfile.bootstrap"
  if [[ -f "$bootstrap_file" ]]; then
    brew_bundle_install "$bootstrap_file"
  else
    HOMEBREW_NO_AUTO_UPDATE=1 brew install node
  fi
}

preflight_node_for_cli

echo "==> preflight: npm ci (cli/)"
(
  cd "$DOTFILES_ROOT/cli"
  npm ci
)

echo "==> dotfiles CLI: install"
cd "$DOTFILES_ROOT/cli"

forward=("$@")
if [[ "${forward[0]:-}" == "--" ]]; then
  forward=("${forward[@]:1}")
fi
if [[ "${forward[0]:-}" == "install" ]]; then
  forward=("${forward[@]:1}")
fi

exec node ./node_modules/tsx/dist/cli.mjs ./src/index.ts install "${forward[@]}"
