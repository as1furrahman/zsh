# zsh [![CI](https://github.com/as1furrahman/zsh/actions/workflows/ci.yml/badge.svg)](https://github.com/as1furrahman/zsh/actions/workflows/ci.yml)

Minimal, sub-60ms Zsh configuration for Arch, Fedora & Ubuntu.

```sh
git clone https://github.com/as1furrahman/zsh.git ~/.config/zsh
cd ~/.config/zsh && ./install.sh
```

### Shortcuts

- `Ctrl+R` — search history (`fzf`)
- `Ctrl+T` / `Ctrl+F` — find files (`fd`)
- `Tab` — fuzzy completion (`fzf-tab`)
- `↑` / `↓` (`k` / `j`) — substring search
- `Ctrl+\` — toggle autosuggestions

### `lf` icons

`lf/icons` is linked to `~/.config/lf/icons` by the installer. `.zshrc` converts
it from lf's native `type<space>icon` format into the colon-separated `LF_ICONS`
string lf actually expects, so both `lf` and any `lf`-aware shell wrapper render
file-type glyphs.

### `/etc/zsh/zshenv`

The installer's `--system` step copies `system/etc/zsh/zshenv`, which exports
`ZDOTDIR` before any user file is read. That file is a dpkg conffile, so a
`zsh-common` upgrade will ask what to do with your locally modified copy:
**keep the current version**. Re-running `./install.sh --system` re-applies it if
the package ever does overwrite it.
