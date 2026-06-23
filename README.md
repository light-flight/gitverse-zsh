# gitverse-zsh

Small zsh plugin with helpers for GitVerse workflows.

## Commands

### `jco <issue-or-text> <branch-title>`

Creates a new git branch using a ticket extracted from the first argument:

```zsh
jco "TSKFRMRVR-123 fix workspace export" fix-workspace-export
# git checkout -b TSKFRMRVR-123/fix-workspace-export
```

### `gpp [-d]`

Pushes the current branch and creates a GitVerse pull request.

```zsh
gpp
gpp -d # create Draft PR
```

For branch `TSKFRMRVR-123/fix-workspace-export`, the PR title will be:

```text
[TSKFRMRVR-123] fix workspace export
```

The PR body will include:

```text
Closes #123

Related to TSKFRMRVR-123
```

## Installation

### Oh My Zsh

Clone the plugin into the custom plugins directory:

```zsh
git clone https://github.com/light-flight/gitverse-zsh "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gitverse"
```

Enable it in `~/.zshrc`:

```zsh
plugins=(git gitverse)
```

Restart the shell or run:

```zsh
source ~/.zshrc
```

### Without A Plugin Manager

Clone the repository anywhere and source the plugin:

```zsh
git clone https://github.com/light-flight/gitverse-zsh "$HOME/.config/gitverse-zsh"
echo 'source "$HOME/.config/gitverse-zsh/gitverse.plugin.zsh"' >> ~/.zshrc
source ~/.zshrc
```

## Configuration

`GITVERSE_TOKEN` is required for `gpp`.

```zsh
export GITVERSE_TOKEN="your-token"
```

Do not commit tokens to this repository or to shared dotfiles. Prefer a private local file, macOS Keychain, 1Password CLI, `pass`, or your team's secret manager.

Optional settings:

```zsh
export GITVERSE_HOST="gitverse.ru"
export GITVERSE_API_URL="https://api.gitverse.ru"
export GITVERSE_TICKET_REGEX="(DTMS|MV|TSKFRMRVR)-[0-9]+"
export GITVERSE_DEFAULT_BASE_BRANCH="main"
export GITVERSE_SKIP_PUSH=1
```

## Dependencies

- `zsh`
- `git`
- `curl`
- `python3`
- `grep`
- `head`

`jco` uses `git checkout -b` directly and does not depend on Oh My Zsh `gco`.

## Updating

Colleagues can update the plugin with:

```zsh
git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gitverse" pull
```

or, for a manual install:

```zsh
git -C "$HOME/.config/gitverse-zsh" pull
```

## Contributing

Keep the public surface small: `jco` and `gpp` should stay stable. Put shared implementation details into `__gitverse_*` helper functions and open a pull request for team-visible changes.

Before opening a PR, run:

```zsh
zsh -n gitverse.plugin.zsh
zsh -n completions/_gpp completions/_jco test/smoke.zsh
zsh test/smoke.zsh
```
