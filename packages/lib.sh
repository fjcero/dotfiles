#!/usr/bin/env bash
# packages/lib.sh - loader for the helper modules in packages/helpers/.
#
# Sourced by bootstrap.sh, export.sh, and individual packages/<name>/{install,export}
# scripts. Do NOT set shell flags here (callers own their flags).
#
# This file:
#   - Auto-resolves DOTFILES_ROOT from its own location if the caller has not set it.
#   - Sources every helper module under packages/helpers/ in dependency order.
#
# Helper layout:
#   packages/helpers/core.sh      generic helpers (require_root, ...)
#   packages/helpers/filters.sh   allow/skip list logic
#   packages/helpers/packages.sh  package discovery + install/export orchestration
#   packages/helpers/io.sh        --output arg parsing and output-dir validation
#   packages/helpers/brew.sh      Homebrew-specific helpers (used by packages/brew/*)
#
# Composability env vars (full list in each module's header):
#   DOTFILES_PACKAGES / DOTFILES_SKIP                 allow / deny lists (skip wins)
#   DOTFILES_EXPORT_PACKAGES / DOTFILES_EXPORT_SKIP   same, but for export (falls back to the above)
#   DOTFILES_EXTRA_PACKAGES_DIRS                      colon-separated roots for out-of-tree packages
#   DOTFILES_EXPORT_ROOT                              base dir for the `home` export (default: $DOTFILES_ROOT/exports)

[[ -n "${__DOTFILES_LIB_LOADED:-}" ]] && return 0
__DOTFILES_LIB_LOADED=1

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DOTFILES_ROOT

_dotfiles_helpers_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/helpers" && pwd)"
# shellcheck source=helpers/core.sh
. "$_dotfiles_helpers_dir/core.sh"
# shellcheck source=helpers/filters.sh
. "$_dotfiles_helpers_dir/filters.sh"
# shellcheck source=helpers/packages.sh
. "$_dotfiles_helpers_dir/packages.sh"
# shellcheck source=helpers/io.sh
. "$_dotfiles_helpers_dir/io.sh"
# shellcheck source=helpers/brew.sh
. "$_dotfiles_helpers_dir/brew.sh"
unset _dotfiles_helpers_dir
