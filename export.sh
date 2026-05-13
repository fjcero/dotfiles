#!/usr/bin/env bash
# export.sh - run package exports: brew updates packages/brew/Brewfile; macos/home write under exports/ (or DOTFILES_EXPORT_ROOT).
#
# Usage:
#   ./export.sh
#   ./export.sh --timestamp
#   ./export.sh -- --skip-system --skip-system-profiler
#
# Optional environment:
#   DOTFILES_EXPORT_ROOT       Base output directory (default: $DOTFILES_ROOT/exports).
#   DOTFILES_EXPORT_PACKAGES   Allow list for export (else falls back to DOTFILES_PACKAGES).
#   DOTFILES_EXPORT_SKIP       Deny list (else falls back to DOTFILES_SKIP).

set -euo pipefail

export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=packages/lib.sh
source "$DOTFILES_ROOT/packages/lib.sh"

timestamp=""
extra=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --timestamp)
      timestamp="$(date +%Y%m%d-%H%M%S)"
      shift
      ;;
    --)
      shift
      extra+=("$@")
      break
      ;;
    *)
      extra+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$timestamp" ]]; then
  export DOTFILES_EXPORT_ROOT="$DOTFILES_ROOT/exports/$timestamp"
fi

echo "Export root: $(dotfiles_export_root)"
dotfiles_run_exports "${extra[@]}"
echo "Export complete."
