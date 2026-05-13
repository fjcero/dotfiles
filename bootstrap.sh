#!/usr/bin/env bash
# bootstrap.sh — apply this dotfiles repo to the current machine.
#
# Usage:
#   ./bootstrap.sh
#
# Optional environment:
#   DOTFILES_PACKAGES      Comma-separated allow list (e.g. brew,home,macos).
#   DOTFILES_SKIP          Comma-separated deny list (skip wins over allow).
#   DOTFILES_HOSTNAME      Set machine hostname via scutil (requires sudo).
#   DOTFILES_RSYNC_DELETE  If 1, home install rsync uses --delete toward $HOME (use with care).

set -euo pipefail

export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=packages/lib.sh
source "$DOTFILES_ROOT/packages/lib.sh"

echo "Bootstrapping from: $DOTFILES_ROOT"

# Install order: brew → macos → home → sudo (do not reorder).
dotfiles_install_package brew "$@"   # Homebrew + Brewfile
dotfiles_install_package macos "$@"  # macOS defaults + optional hostname
dotfiles_install_package home "$@"   # repo home/ → $HOME (rsync) + chsh
dotfiles_install_package sudo "$@"   # Touch ID for sudo (requires sudo)

echo "Bootstrap complete."
