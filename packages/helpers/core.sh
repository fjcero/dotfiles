#!/usr/bin/env bash
# packages/helpers/core.sh - small, generic helpers used by every other module.
# Sourced; do NOT set shell flags here (callers own their flags).

[[ -n "${__DOTFILES_HELPERS_CORE:-}" ]] && return 0
__DOTFILES_HELPERS_CORE=1

dotfiles_require_root() {
  if [[ -z "${DOTFILES_ROOT:-}" ]] || [[ ! -d "$DOTFILES_ROOT" ]]; then
    echo "DOTFILES_ROOT must be set to the dotfiles repository root." >&2
    return 1
  fi
}
