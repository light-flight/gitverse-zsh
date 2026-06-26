#!/usr/bin/env zsh

set -euo pipefail

ZSHRC="${ZSHRC:-$HOME/.zshrc}"
install_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gitverse"

if [[ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]]; then
  echo "Oh My Zsh is required." >&2
  exit 1
fi

__gitverse_sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

if [[ -d "$install_dir" ]]; then
  rm -rf "$install_dir"
  echo "Removed $install_dir"
else
  echo "Plugin directory not found: $install_dir"
fi

if grep -q 'plugins=.*gitverse' "$ZSHRC" 2>/dev/null; then
  __gitverse_sed_inplace '/^plugins=/s/ gitverse//; /^plugins=/s/gitverse //; s/^plugins=(gitverse)/plugins=()/' "$ZSHRC"
  echo "Removed gitverse from plugins in $ZSHRC"
else
  echo "gitverse not found in plugins in $ZSHRC"
fi

echo "GitVerse plugin uninstalled."
