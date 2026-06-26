#!/usr/bin/env zsh

set -euo pipefail

REPO_URL="https://github.com/light-flight/gitverse-zsh.git"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
install_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gitverse"

if [[ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]]; then
  echo "Oh My Zsh is required. Install it first: https://ohmyz.sh" >&2
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
  git -C "$install_dir" pull --ff-only
else
  git clone "$REPO_URL" "$install_dir"
fi

if ! grep -q 'plugins=.*gitverse' "$ZSHRC" 2>/dev/null; then
  __gitverse_sed_inplace 's/^plugins=(\(.*\))/plugins=(\1 gitverse)/' "$ZSHRC"
fi

echo "GitVerse plugin installed."
echo "Restart your shell or run: source \"$ZSHRC\""
