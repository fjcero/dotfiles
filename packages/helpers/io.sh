#!/usr/bin/env bash
# packages/helpers/io.sh - argument and output-directory helpers shared by package export scripts.
# Sourced; do NOT set shell flags here (callers own their flags).

[[ -n "${__DOTFILES_HELPERS_IO:-}" ]] && return 0
__DOTFILES_HELPERS_IO=1

# dotfiles_parse_output_arg "$@"
#   Consumes `--output|-o <dir>` from the script arguments.
#   Sets DOTFILES_OUTPUT_DIR (string) to the captured directory (empty if absent).
#   Sets DOTFILES_REST_ARGS (array) to the remaining, un-consumed arguments.
dotfiles_parse_output_arg() {
  DOTFILES_OUTPUT_DIR=""
  DOTFILES_REST_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --output|-o)
        if [[ $# -lt 2 ]]; then
          printf 'error: %s requires a directory argument\n' "$1" >&2
          return 1
        fi
        DOTFILES_OUTPUT_DIR="$2"
        shift 2
        ;;
      *)
        DOTFILES_REST_ARGS+=("$1")
        shift
        ;;
    esac
  done
}

# dotfiles_require_output_dir <dir>
#   Fails (exit 1) if <dir> is empty; otherwise mkdir -p the directory.
dotfiles_require_output_dir() {
  local dir="${1:-}"
  if [[ -z "$dir" ]]; then
    printf 'error: missing --output <dir>\n' >&2
    return 1
  fi
  mkdir -p "$dir"
}
