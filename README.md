# ⚡ Reproducible Zsh Dotfile Configuration

A high-performance, modular, and tastefully minimal **Zsh** configuration engineered for **Ubuntu 26.04.1 LTS** (and modern Linux distributions).

Designed around **XDG Base Directory standards**, native **Zsh bytecode compilation (`.zwc`)**, **lazy-loaded runtimes**, and an interactive startup time under **70 ms**.

---

## 🚀 Reproduction on Another Ubuntu 26.04.1 LTS System

### Option A: Standard Setup (Clone into `~/Projects/zsh`)

```bash
# 1. Clone repository
git clone <your-repo-url> ~/Projects/zsh
cd ~/Projects/zsh

# 2. Run the automated installer
./install.sh
```

### Option B: Direct XDG Setup (Clone directly into `~/.config/zsh`)

```bash
# 1. Clone directly into XDG configuration directory
git clone <your-repo-url> ~/.config/zsh
cd ~/.config/zsh

# 2. Run the installer
./install.sh
```

---

## 🛠️ What the Installer Does

The `./install.sh` script is **idempotent**, safe, and fully automated:

1. **Installs System Dependencies**:
   * APT packages: `zsh`, `neovim`, `eza`, `bat`, `fd-find`, `fzf`, `ripgrep`, `git`, `curl`
   * Installs [`starship`](https://starship.rs) and [`zoxide`](https://github.com/ajeetdsouza/zoxide)
   * Resolves Ubuntu binary naming differences (`batcat` ➔ `~/.local/bin/bat`, `fdfind` ➔ `~/.local/bin/fd`)
2. **Configures XDG File Topology**:
   * Symlinks configuration modules into `~/.config/zsh/` (or preserves direct clone)
   * Creates required runtime directories (`~/.local/state/zsh` for history, `~/.cache/zsh` for completion cache)
3. **Installs `/etc/zsh/zshenv`** (requires `sudo`):
   * Sets `$ZDOTDIR` to `~/.config/zsh` system-wide so Zsh never looks for or leaves dotfiles in `$HOME`.
   * Integrates cleanly with **Ghostty** terminal integration (`GHOSTTY_ZSH_ZDOTDIR`).
4. **Pre-compiles Bytecode (`.zwc`)**:
   * Pre-compiles all configuration scripts to bytecode so your first shell launch is instantaneous.
5. **Sets Default Shell**:
   * Safely switches your user login shell to `zsh` via `chsh`.

### Installer Options & Flags

```bash
./install.sh [OPTIONS]

  --all         Install deps, configure files, setup system zshenv, and change shell (Default)
  --deps        Install Ubuntu packages, starship, zoxide & CLI symlinks only
  --config      Link/install configuration files to ~/.config/zsh only
  --system      Install /etc/zsh/zshenv (requires sudo)
  --shell       Set default login shell to zsh via chsh
  -n, --dry-run Preview all operations without touching the system
  -h, --help    Show help message
```

---

## 📁 Repository Structure

```
.
├── .zshenv             # XDG base directories, deduplicated PATH, EDITOR, completion guard
├── .zshrc              # Shell options, history, compinit caching, NVM lazy loading
├── aliases.zsh         # eza, bat, ripgrep, navigation, lf directory following, git aliases
├── bindings.zsh        # Vi-mode keymaps, cursor shapes, fzf integration, substring search
├── fzf.zsh             # fzf options, fd integration, rich fzf-tab contextual previews
├── plugins.zsh         # Built-in git auto-cloner, async autosuggestions, updater
├── prompt.zsh          # Starship initialization with dumb-terminal guard
├── starship.toml       # Prompt theme & status indicators
├── install.sh          # Idempotent Ubuntu 26.04.1 reproduction script
├── .gitignore          # Ignores .zwc, compdump, and auto-cloned plugins
└── system/
    └── etc/zsh/zshenv  # System-wide root file to point ZDOTDIR -> ~/.config/zsh
```

---

## 🔌 Plugins Included

Plugins are managed without external bloatware managers (no Oh My Zsh or heavy plugin frameworks). They clone automatically via `git --depth=1` on first shell start and compile to `.zwc`:

| Plugin | Source | Purpose |
| :--- | :--- | :--- |
| **`fzf-tab`** | `Aloxaf/fzf-tab` | Interactive fuzzy completion with live file/directory preview |
| **`fast-syntax-highlighting`** | `zdharma-continuum` | Syntax highlighting |
| **`zsh-autosuggestions`** | `zsh-users` | Fish-like asynchronous line suggestions |
| **`zsh-history-substring-search`** | `zsh-users` | Fuzzy substring search through command history |
| **`zsh-vi-mode`** | `jeffreytse` | Vi emulation with cursor styling and hook retention |

### Updating Plugins
To pull the latest updates for all installed plugins:
```bash
zplugin-update
```

---

## ⌨️ Keybindings

| Keybinding | Action | Keymap |
| :--- | :--- | :--- |
| `Ctrl + R` | Fuzzy history search (`fzf`) | Insert / Normal |
| `Ctrl + T` | Fuzzy file search including hidden files (`fzf` + `fd`) | Insert / Normal |
| `Ctrl + F` | Fuzzy file search excluding hidden files (`fzf` + `fd`) | Insert / Normal |
| `Tab` | Context-aware fuzzy completion (`fzf-tab`) | Insert |
| `↑` / `↓` | History search by typed substring | Insert / Normal |
| `k` / `j` | History search by typed substring | Normal (`vicmd`) |
| `Ctrl + →` | Move cursor forward one word | Insert |
| `Ctrl + ←` | Move cursor backward one word | Insert |
| `Ctrl + \` | Toggle inline autosuggestions (useful for screen sharing) | Insert / Normal |

---

## ⚙️ Performance & Architecture Details

1. **Sub-70ms Startup**:
   Startup latency benchmarks at **~66 ms**.
2. **Lazy NVM Resolution**:
   Unlike standard `nvm.sh` which can add 400–800 ms to every shell spawn, this setup parses `$NVM_DIR/alias/default` in pure shell and prepends node’s `bin` directly to `$PATH` in **0.5 ms**. Full NVM functions are only loaded when you explicitly execute `nvm`.
3. **20-Hour Compdump Guard**:
   `compaudit` runs once every 20 hours (`(#qN.mh-20)`). Repeated shell invocations reuse the cached `zcompdump.zwc` bytecode dump via `compinit -C`.
4. **Clean Non-Interactive Shells**:
   Non-interactive subshells and automated scripts (`zsh -c "..."`) execute cleanly without prompt pollution or unnecessary hook execution.
5. **Machine-Local Overrides**:
   If a file named `~/.config/zsh/local.zsh` exists, it is automatically sourced at the end of `.zshrc`. Use this for machine-specific API keys, custom environment variables, or work-specific tokens.
