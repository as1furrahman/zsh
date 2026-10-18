# zsh

Minimal, sub-60ms Zsh configuration for Ubuntu 26.04 LTS.

## Install

```sh
git clone git@github.com:as1furrahman/zsh.git ~/Projects/zsh
cd ~/Projects/zsh
./install.sh
```

## Keybindings

| Key | Action |
|---|---|
| `Ctrl+R` | Fuzzy history search (`fzf`) |
| `Ctrl+T` | Fuzzy file search (`fd` + `fzf`) |
| `Ctrl+F` | Fuzzy file search excluding hidden files |
| `Tab` | Context-aware fuzzy completion (`fzf-tab`) |
| `↑` / `↓` (`k` / `j`) | History search by typed substring |
| `Ctrl+→` / `Ctrl+←` | Move cursor forward / backward by word |
| `Ctrl+\` | Toggle inline autosuggestions |

## Plugins

* [`fzf-tab`](https://github.com/Aloxaf/fzf-tab) — Interactive fuzzy completion
* [`fast-syntax-highlighting`](https://github.com/zdharma-continuum/fast-syntax-highlighting) — Syntax highlighting
* [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) — Async suggestions
* [`zsh-history-substring-search`](https://github.com/zsh-users/zsh-history-substring-search) — Substring search
* [`zsh-vi-mode`](https://github.com/jeffreytse/zsh-vi-mode) — Vi emulation

Update plugins anytime with `zplugin-update`.
