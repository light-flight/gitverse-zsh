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

## Installation

Requires [Oh My Zsh](https://ohmyz.sh). One command — idempotent, safe to re-run for updates:

```zsh
curl -fsSL https://raw.githubusercontent.com/light-flight/gitverse-zsh/main/install.sh | zsh
```

Or, from a local clone:

```zsh
zsh install.sh
```

Installs into `custom/plugins/gitverse` and adds `gitverse` to `plugins=(...)` in `~/.zshrc`.

## Uninstallation

```zsh
curl -fsSL https://raw.githubusercontent.com/light-flight/gitverse-zsh/main/uninstall.sh | zsh
```

Or, from a local clone:

```zsh
zsh uninstall.sh
```

Removes `custom/plugins/gitverse` and `gitverse` from `plugins=(...)` in `~/.zshrc`.

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
export GITVERSE_DEFAULT_BASE_BRANCH="master"
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

Re-run the install command.

## Contributing

Keep the public surface small: `jco` and `gpp` should stay stable. Put shared implementation details into `__gitverse_*` helper functions and open a pull request for team-visible changes.

Before opening a PR, run:

```zsh
zsh -n gitverse.plugin.zsh
zsh -n completions/_gpp completions/_jco test/smoke.zsh
zsh test/smoke.zsh
```
