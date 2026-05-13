#!/usr/bin/env bash
# packages/helpers/filters.sh - allow/skip list logic for package selection.
# Sourced; do NOT set shell flags here (callers own their flags).
#
# Env vars consulted by dotfiles_export_allow / dotfiles_export_deny:
#   DOTFILES_EXPORT_PACKAGES  Optional. Allow list for export (falls back to DOTFILES_PACKAGES).
#   DOTFILES_EXPORT_SKIP      Optional. Deny list for export (falls back to DOTFILES_SKIP).

[[ -n "${__DOTFILES_HELPERS_FILTERS:-}" ]] && return 0
__DOTFILES_HELPERS_FILTERS=1

dotfiles_list_contains() {
  local needle="$1"
  local IFS=','
  local item
  for item in $2; do
    item="${item//[[:space:]]/}"
    [[ -z "$item" ]] && continue
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

# Skip wins: if name is in $deny return 1 (do not run).
# If $allow is set and name is not in it, return 1. Otherwise return 0.
dotfiles_should_run_name() {
  local name="$1"
  local allow="${2:-}"
  local deny="${3:-}"

  if [[ -n "$deny" ]] && dotfiles_list_contains "$name" "$deny"; then
    return 1
  fi
  if [[ -n "$allow" ]] && ! dotfiles_list_contains "$name" "$allow"; then
    return 1
  fi
  return 0
}

dotfiles_export_allow() {
  if [[ -n "${DOTFILES_EXPORT_PACKAGES:-}" ]]; then
    printf '%s' "$DOTFILES_EXPORT_PACKAGES"
  elif [[ -n "${DOTFILES_PACKAGES:-}" ]]; then
    printf '%s' "$DOTFILES_PACKAGES"
  fi
}

dotfiles_export_deny() {
  if [[ -n "${DOTFILES_EXPORT_SKIP:-}" ]]; then
    printf '%s' "$DOTFILES_EXPORT_SKIP"
  elif [[ -n "${DOTFILES_SKIP:-}" ]]; then
    printf '%s' "$DOTFILES_SKIP"
  fi
}
