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
curl -fsSL https://raw.githubusercontent.com/light-flight/gitverse-zsh/main/install.sh | zsh && source ~/.zshrc
```

It installs the plugin, enables it in `~/.zshrc`, and prompts you to paste your GitVerse token (stored in macOS Keychain). That's it — `gpp` reads the token from Keychain automatically, nothing in plaintext. Re-run anytime to update.

## Uninstallation

```zsh
curl -fsSL https://raw.githubusercontent.com/light-flight/gitverse-zsh/main/uninstall.sh | zsh && source ~/.zshrc
```

Removes `custom/plugins/gitverse` and `gitverse` from `plugins=(...)` in `~/.zshrc`.

## Configuration

`gpp` needs a GitVerse token — set up via macOS Keychain in [Installation](#installation).

`GITVERSE_TOKEN` (env var) still works as an override and takes precedence over Keychain. To use a different Keychain entry, set `GITVERSE_KEYCHAIN_SERVICE`.

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
