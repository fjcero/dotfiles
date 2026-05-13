#!/usr/bin/env bash
# packages/helpers/brew.sh - Homebrew helpers shared by packages/brew/{install,export}.
# Sourced; do NOT set shell flags here (callers own their flags).

[[ -n "${__DOTFILES_HELPERS_BREW:-}" ]] && return 0
__DOTFILES_HELPERS_BREW=1

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
