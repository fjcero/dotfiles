#!/usr/bin/env bash
# bootstrap.sh - from-scratch machine setup (delegates to packages/*).
#
# Usage:
#   ./bootstrap.sh
#
# Optional environment:
#   DOTFILES_PACKAGES      Comma-separated allow list (e.g. brew,home,macos).
#   DOTFILES_SKIP          Comma-separated deny list (skip wins over allow).
#   DOTFILES_SYSTEM=1      Also run root packages (sudo, hosts).
#   DOTFILES_HOME_MODE     rsync (default) or stow — how repo home/ is applied to $HOME.
#   DOTFILES_RSYNC_DELETE  If 1 with rsync mode, rsync uses --delete (use with care).

set -euo pipefail

export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=packages/lib.sh
source "$DOTFILES_ROOT/packages/lib.sh"

echo "Bootstrapping from: $DOTFILES_ROOT"
dotfiles_run_installs
echo "Bootstrap complete."
