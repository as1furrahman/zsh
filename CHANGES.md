# Changes on branch `fahmid`

Review notes for the changes made on top of `main`. Commits are grouped by scope.

## 1. Remove machine-specific hard-coding
- Removed the `stream` alias (`/dev/video4`), the `~/Projects/dotfile` alias branch,
  `~/.strix/bin` from `PATH`, `LF_ICONS` loading and the "Ubuntu 26.04" header comment.
- The `dotfiles` alias now only exists when `$ZDOTDIR` is itself a git checkout.
- **Kept on purpose:** the `GHOSTTY_ZSH_ZDOTDIR` export in `system/etc/zsh/zshenv`.
  Ghostty's shell integration needs it to locate the real config, so removing it
  could break Ghostty users.

## 2. nvm -> mise
- Deleted the ~70-line nvm alias resolver and lazy `nvm()` wrapper from `.zshrc`.
- Added a guarded `eval "$(mise activate zsh)"`.

## 3. One fzf loader
- `_fzf_init` replaces two duplicated copies of the fzf search-path list
  (`.zshrc` and `zvm_after_init` in `bindings.zsh`). `_fzf_init keys` re-binds
  without reloading completion.
- The fzf-tab file/dir preview used `a && b || c && d`; it is now `if/elif`, so
  a failing `bat` no longer falls through to the directory branch.

## 4. Shell behaviour
- `SHARE_HISTORY` replaces `INC_APPEND_HISTORY_TIME` (live history sharing;
  timestamps still come from `EXTENDED_HISTORY`).
- Removed `EXTENDED_GLOB` so `HEAD^`, `#` and `~` work unquoted. The compinit
  freshness check used `(#q...)`, which needs it, so it was rewritten with a
  plain `(N.mh-20)` qualifier.
- Added application-mode arrow bindings (`^[OA`, `^[OB`) for substring search.
- `KEYTIMEOUT` 1 -> 5 (50 ms) so multi-byte key sequences survive slow SSH.

## 5. Installer safety
- `pacman -Syu --noconfirm` -> `pacman -S --needed --noconfirm` (no full system
  upgrade as a side effect).
- Removed the `curl | sh` fallbacks for starship and zoxide; it warns instead.
- `chsh` errors are shown instead of discarded.
- `system/etc/zsh/zshenv` comments are no longer Ubuntu/dpkg specific.

## 6. Plugin pinning
- New `plugins.lock` (`owner name sha`). `install.sh --config` installs each
  plugin at its pinned commit and links the lock file into `~/.config/zsh`.
- Shell startup no longer runs `git clone`. Missing plugins produce one hint line.
- `zplugin-update` reports drift against upstream; `zplugin-update --apply`
  checks out the new commit and prints the line to put in `plugins.lock`.

## 7. Day-to-day shell (second round)
- **Vi mode is opt-in** (`ZSH_VI=1`). In vi normal mode a terminal paste
  (Ctrl+Shift+V) is read as commands, so zsh-vi-mode is no longer loaded by
  default. Bindings moved into `_zsh_bindings`, which runs directly, or from
  `zvm_after_init` when vi mode is on.
- **History**: 1,000,000 entries, `HIST_IGNORE_SPACE` and early expiry removed,
  so every command is kept. Shared live between sessions (`SHARE_HISTORY`).
- **Native prompt** (`prompt.zsh`): each path level in its own color, repo name,
  branch, staged/modified/untracked/conflict counts, ahead/behind, exit status,
  command duration (>= 2s) and clock. `ZSH_PROMPT=starship` restores starship.
- Verified in a pty: multi-line bracketed paste does not execute (no output, no
  side effects) until Enter is pressed.

## Not changed
Prompt (`starship.toml`), alias set and zsh-vi-mode were left alone.

## Verification status
- `bash -n install.sh` and `./install.sh --deps|--config --dry-run`: pass.
- Fetching a plugin by exact SHA (`git fetch --depth=1 origin <sha>`): verified.
- **Not run:** zsh was not installed on the author's machine, so `zsh -n`,
  startup timing and key bindings are untested. Please run `zsh -n` on each
  file and open an interactive shell before merging.
