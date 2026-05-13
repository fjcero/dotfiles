#!/usr/bin/env bash
# bootstrap.sh — apply this dotfiles repo to the current machine (userland install steps).
#
# Usage:
#   ./bootstrap.sh
#
# Applying home/ uses packages/home/install → dotfiles_apply_home in packages/lib.sh
# (DOTFILES_HOME_MODE, DOTFILES_RSYNC_DELETE).
# Privileged steps (sudo, hosts) are not run here; use a separate script when ready.
#
# Optional environment:
#   DOTFILES_PACKAGES      Comma-separated allow list (e.g. brew,home,macos).
#   DOTFILES_SKIP          Comma-separated deny list (skip wins over allow).
#   DOTFILES_HOME_MODE     rsync (default) or stow — how repo home/ is applied to $HOME.
#   DOTFILES_RSYNC_DELETE  If 1 with rsync mode, rsync uses --delete (use with care).

set -euo pipefail

export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=packages/lib.sh
source "$DOTFILES_ROOT/packages/lib.sh"

echo "Bootstrapping from: $DOTFILES_ROOT"

# Install order is intentional: brew → macos config → home configs.
dotfiles_install_package brew "$@"   # Homebrew + Brewfile
dotfiles_install_package macos "$@"  # macOS defaults (packages/macos)
dotfiles_install_package home "$@"   # repo home/ → $HOME (rsync or stow)

echo "Bootstrap complete."
