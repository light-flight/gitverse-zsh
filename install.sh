#!/usr/bin/env zsh

set -euo pipefail

REPO_URL="https://github.com/light-flight/gitverse-zsh.git"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
KEYCHAIN_SERVICE="${GITVERSE_KEYCHAIN_SERVICE:-gitverse-token}"
install_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gitverse"

__gv_info() { print -P "%F{cyan}==>%f $1"; }
__gv_ok() { print -P "%F{green}✓%f $1"; }
__gv_err() { print -P "%F{red}✗%f $1" >&2; }

if [[ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]]; then
  __gv_err "Oh My Zsh is required. Install it first: https://ohmyz.sh"
  exit 1
fi

__gitverse_sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

if [[ -d "$install_dir/.git" ]]; then
  __gv_info "Updating plugin..."
  git -C "$install_dir" pull --ff-only >/dev/null
else
  __gv_info "Cloning plugin..."
  git clone --quiet "$REPO_URL" "$install_dir"
fi
__gv_ok "Plugin in $install_dir"

if grep -q 'plugins=.*gitverse' "$ZSHRC" 2>/dev/null; then
  __gv_ok "Already enabled in plugins"
else
  __gitverse_sed_inplace 's/^plugins=(\(.*\))/plugins=(\1 gitverse)/' "$ZSHRC"
  __gv_ok "Enabled in plugins"
fi

if [[ -r /dev/tty ]]; then
  __gv_info "Paste your GitVerse token (input hidden), or press Enter to skip:"
  IFS= read -rs gv_token </dev/tty || gv_token=""
  print
  if [[ -n "$gv_token" ]]; then
    security add-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -U -w "$gv_token"
    unset gv_token
    __gv_ok "Token stored in Keychain"
  else
    __gv_info "Skipped token. Set it later with:"
    print "    security add-generic-password -a \"\$USER\" -s $KEYCHAIN_SERVICE -U -w"
  fi
else
  __gv_info "Set your token later with:"
  print "    security add-generic-password -a \"\$USER\" -s $KEYCHAIN_SERVICE -U -w"
fi

__gv_ok "Done. Restart your shell or run: source \"$ZSHRC\""
