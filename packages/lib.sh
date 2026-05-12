#!/usr/bin/env bash
# packages/lib.sh - shared helpers for bootstrap and export (source only; no shebang execution side effects).
#
# Environment:
#   DOTFILES_ROOT          Repo root (required). Set by bootstrap.sh / export.sh before sourcing.
#
# Composability (install + export):
#   DOTFILES_PACKAGES      Optional comma-separated allow list (if set, only these names run).
#   DOTFILES_SKIP          Optional comma-separated deny list (skip wins over allow).
#   DOTFILES_SYSTEM=1      Required to run root packages (sudo, hosts) during bootstrap.
#   DOTFILES_EXTRA_PACKAGES_DIRS  Colon-separated roots; each has packages/<name>/install (or export).
#
# Apply repo home/ into $HOME:
#   DOTFILES_HOME_MODE     rsync (default) or stow.
#   DOTFILES_RSYNC_DELETE  If 1 with rsync mode, pass --delete to rsync (dangerous on $HOME).
#
# Export-only (falls back to DOTFILES_* when unset):
#   DOTFILES_EXPORT_PACKAGES
#   DOTFILES_EXPORT_SKIP
#   DOTFILES_EXPORT_ROOT   Base directory for per-package outputs (default: $DOTFILES_ROOT/exports).

set -euo pipefail

dotfiles_require_root() {
  if [[ -z "${DOTFILES_ROOT:-}" ]] || [[ ! -d "$DOTFILES_ROOT" ]]; then
    echo "DOTFILES_ROOT must be set to the dotfiles repository root." >&2
    return 1
  fi
}

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

# skip wins: if in SKIP, return 1 (do not run). If PACKAGES set and not in PACKAGES, return 1. Else 0.
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

dotfiles_find_package_script() {
  local name="$1"
  local script_name="$2"
  local path="$DOTFILES_ROOT/packages/$name/$script_name"

  if [[ -x "$path" ]]; then
    printf '%s' "$path"
    return 0
  fi

  local root
  if [[ -z "${DOTFILES_EXTRA_PACKAGES_DIRS:-}" ]]; then
    return 1
  fi

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

dotfiles_export_root() {
  local base="${DOTFILES_EXPORT_ROOT:-$DOTFILES_ROOT/exports}"
  printf '%s' "$base"
}

ensure_brew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_bundle_install() {
  local brewfile="$1"
  if [[ ! -f "$brewfile" ]]; then
    echo "Missing Brewfile: $brewfile" >&2
    return 1
  fi
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file="$brewfile"
}

# Copy or symlink repo home/ into $HOME (excludes README.md and .stow-local-ignore from rsync).
dotfiles_apply_home() {
  dotfiles_require_root || return 1
  local src="$DOTFILES_ROOT/home"
  [[ -d "$src" ]] || {
    echo "No $src; skipping home apply."
    return 0
  }

  local mode="${DOTFILES_HOME_MODE:-rsync}"
  case "$mode" in
    rsync)
      if ! command -v rsync >/dev/null 2>&1; then
        echo "rsync not found; install rsync or set DOTFILES_HOME_MODE=stow" >&2
        return 1
      fi
      local rsync_args=(-a --exclude='README.md' --exclude='.stow-local-ignore')
      if [[ "${DOTFILES_RSYNC_DELETE:-0}" == "1" ]]; then
        rsync_args+=(--delete)
      fi
      echo "Applying home/ -> \$HOME via rsync (${rsync_args[*]}) ..."
      rsync "${rsync_args[@]}" "$src/" "$HOME/"
      ;;
    stow)
      if ! command -v stow >/dev/null 2>&1; then
        echo "stow not found; install gnu-stow or set DOTFILES_HOME_MODE=rsync" >&2
        return 1
      fi
      echo "Stowing package home -> \$HOME ..."
      stow -R -v -t "$HOME" -d "$DOTFILES_ROOT" home
      ;;
    *)
      echo "Unknown DOTFILES_HOME_MODE=$mode (use rsync or stow)" >&2
      return 1
      ;;
  esac
}

dotfiles_run_installs() {
  dotfiles_require_root || return 1
  local allow="${DOTFILES_PACKAGES:-}"
  local deny="${DOTFILES_SKIP:-}"

  local order=(
    brew
    macos
    home
  )

  local name path
  for name in "${order[@]}"; do
    dotfiles_should_run_name "$name" "$allow" "$deny" || continue

    if [[ "$name" == "sudo" ]] || [[ "$name" == "hosts" ]]; then
      continue
    fi

    path=""
    if path="$(dotfiles_find_package_script "$name" install)"; then
      :
    else
      path=""
    fi
    [[ -z "${path:-}" ]] && continue
    echo "==> install: $name"
    "$path" "$@"
  done

  if [[ "${DOTFILES_SYSTEM:-0}" == "1" ]]; then
    for name in sudo hosts; do
      dotfiles_should_run_name "$name" "$allow" "$deny" || continue
      path=""
      if path="$(dotfiles_find_package_script "$name" install)"; then
        :
      else
        path=""
      fi
      [[ -z "${path:-}" ]] && continue
      echo "==> install (system): $name"
      "$path" "$@"
    done
  fi
}

dotfiles_run_exports() {
  dotfiles_require_root || return 1
  local allow
  local deny
  allow="$(dotfiles_export_allow)"
  deny="$(dotfiles_export_deny)"
  local export_root
  export_root="$(dotfiles_export_root)"

  local order=(brew macos home)

  local name path out
  for name in "${order[@]}"; do
    dotfiles_should_run_name "$name" "$allow" "$deny" || continue
    path=""
    if path="$(dotfiles_find_package_script "$name" export)"; then
      :
    else
      path=""
    fi
    [[ -z "${path:-}" ]] && continue
    out="$export_root/$name"
    mkdir -p "$out"
    echo "==> export: $name -> $out"
    # Per-package export receives output directory as first arg after any global flags handled by caller.
    "$path" --output "$out" "$@"
  done
}
