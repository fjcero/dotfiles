#!/usr/bin/env bash
# packages/helpers/packages.sh - package discovery and install/export orchestration.
# Sourced; do NOT set shell flags here (callers own their flags).
#
# Env vars consulted here:
#   DOTFILES_ROOT                 Repo root (required).
#   DOTFILES_PACKAGES             Optional comma-separated allow list (install).
#   DOTFILES_SKIP                 Optional comma-separated deny list (install; skip wins).
#   DOTFILES_EXTRA_PACKAGES_DIRS  Colon-separated extra roots, each containing packages/<name>/install (or export).
#   DOTFILES_EXPORT_ROOT          Base directory for the `home` export (default: $DOTFILES_ROOT/exports).

[[ -n "${__DOTFILES_HELPERS_PACKAGES:-}" ]] && return 0
__DOTFILES_HELPERS_PACKAGES=1

dotfiles_find_package_script() {
  local name="$1"
  local script_name="$2"
  local path="$DOTFILES_ROOT/packages/$name/$script_name"

  if [[ -x "$path" ]]; then
    printf '%s' "$path"
    return 0
  fi

  if [[ -z "${DOTFILES_EXTRA_PACKAGES_DIRS:-}" ]]; then
    return 1
  fi

  local root
  local IFS=':'
  for root in $DOTFILES_EXTRA_PACKAGES_DIRS; do
    root="${root/#\~/$HOME}"
    [[ -z "$root" ]] && continue
    path="$root/packages/$name/$script_name"
    if [[ -x "$path" ]]; then
      printf '%s' "$path"
      return 0
    fi
  done
  return 1
}

dotfiles_export_root() {
  local base="${DOTFILES_EXPORT_ROOT:-$DOTFILES_ROOT/exports}"
  printf '%s' "$base"
}

dotfiles_install_package() {
  local name="$1"
  shift
  dotfiles_require_root || return 1
  local allow="${DOTFILES_PACKAGES:-}"
  local deny="${DOTFILES_SKIP:-}"

  dotfiles_should_run_name "$name" "$allow" "$deny" || return 0

  local path=""
  if path="$(dotfiles_find_package_script "$name" install)"; then
    :
  else
    return 0
  fi

  if [[ "$name" == "sudo" || "$name" == "hosts" ]]; then
    echo "==> install (system): $name"
  else
    echo "==> install: $name"
  fi
  "$path" "$@"
}

dotfiles_run_exports() {
  dotfiles_require_root || return 1
  local allow deny export_root
  allow="$(dotfiles_export_allow)"
  deny="$(dotfiles_export_deny)"
  export_root="$(dotfiles_export_root)"

  local order=(brew macos home)

  local name path out
  for name in "${order[@]}"; do
    dotfiles_should_run_name "$name" "$allow" "$deny" || continue
    path=""
    if path="$(dotfiles_find_package_script "$name" export)"; then
      :
    else
      continue
    fi
    case "$name" in
      brew|macos) out="$DOTFILES_ROOT/packages/$name" ;;
      *)          out="$export_root/$name" ;;
    esac
    mkdir -p "$out"
    echo "==> export: $name -> $out"
    "$path" --output "$out" "$@"
  done
}
