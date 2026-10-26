# Powerful but tastefully minimal zsh configuration
# Follows the XDG Base Directory specification

# =========================================================
# ZDOTDIR Fallback
# =========================================================

# /etc/zsh/zshenv exports ZDOTDIR pointing to ~/.config/zsh.
# Fall back if invoked directly or variable was cleared.
if [[ -z "$ZDOTDIR" ]]; then
  ZDOTDIR="$HOME/.config/zsh"
fi

# =========================================================
# History
# =========================================================

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
[[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" ]] || mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
HISTSIZE=1000000
SAVEHIST=1000000

setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt EXTENDED_HISTORY         # Record timestamp (epoch) and execution duration
setopt SHARE_HISTORY            # Share history live between sessions (implies incremental append)
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks from history commands

# =========================================================
# Shell Behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT       # Sort file10 after file9, not after file1
setopt EXTENDED_GLOB           # Enable advanced zsh glob qualifiers and patterns
setopt INTERACTIVE_COMMENTS    # '#' at the prompt starts a comment
setopt AUTO_PUSHD              # Make cd push old directory to stack
setopt PUSHD_IGNORE_DUPS       # Don't push duplicate directories to stack
setopt PUSHD_SILENT            # Don't print directory stack after pushd/popd

# =========================================================
# Smart Directory Navigation & Tools
# =========================================================

# lf reads LF_ICONS as one colon-separated string, while the icons file is
# lf's native "type<space>icon" format, so fold it into key:icon pairs here.
if [[ -z "$LF_ICONS" && -f ~/.config/lf/icons ]]; then
  LF_ICONS=$(awk '!/^#/ && NF >= 2 { printf "%s:%s:", $1, $2 }' ~/.config/lf/icons)
  export LF_ICONS
fi
# Initialize zoxide (smart cd replacement)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Per-directory environments (.envrc) via direnv
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# =========================================================
# Completion System
# =========================================================

autoload -Uz compinit

# Fast compinit: run compaudit check once every 20 hours; otherwise reuse dump cache (-C)
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
# (N.mh-20): plain file modified within the last 20 hours; needs no EXTENDED_GLOB
_zcompdump_fresh=("$_zcompdump"(N.mh-20))
if (( $#_zcompdump_fresh )); then
  compinit -C -d "$_zcompdump"
else
  compinit -d "$_zcompdump"
  { zcompile "$_zcompdump" } >/dev/null 2>&1 &!
fi
unset _zcompdump _zcompdump_fresh

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Make completion case-insensitive (doc matches Documents)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# =========================================================
# Fuzzy Finder (fzf key-bindings and completion)
# =========================================================

# Source fzf's shell integration from whichever location this system ships it.
# Usage: _fzf_init [keys]   ("keys" skips completion, for re-binding only)
_fzf_init() {
  local dir
  for dir in \
    /opt/homebrew/opt/fzf/shell \
    /usr/local/opt/fzf/shell \
    /usr/share/fzf \
    /usr/share/doc/fzf/examples \
    "$HOME/.fzf/shell"; do
    if [[ -f "$dir/key-bindings.zsh" ]]; then
      source "$dir/key-bindings.zsh"
      [[ "$1" != keys && -f "$dir/completion.zsh" ]] && source "$dir/completion.zsh"
      return 0
    fi
  done

  # Fallback for standalone fzf binary installations
  command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh 2>/dev/null)"
}

_fzf_init

# =========================================================
# Modular Config Modules
# =========================================================

source "$ZDOTDIR/fzf.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/plugins.zsh"
[[ -z $ZSH_VI ]] && _zsh_bindings
source "$ZDOTDIR/prompt.zsh"

# =========================================================
# Runtime Versions (mise)
# =========================================================

# Per-project node/python/etc. versions; replaces the old nvm fast-path.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# =========================================================
# Machine-Local Overrides
# =========================================================

if [[ -f "$ZDOTDIR/local.zsh" ]]; then
  source "$ZDOTDIR/local.zsh"
fi

# =========================================================
# Background Bytecode Compilation (.zwc)
# =========================================================

# Auto-compile modified config files to bytecode in background for instant sub-70ms startup
() {
  local f
  for f in "$ZDOTDIR"/.zshrc "$ZDOTDIR"/.zshenv "$ZDOTDIR"/*.zsh; do
    if [[ -f "$f" && (! -f "${f}.zwc" || "$f" -nt "${f}.zwc") ]]; then
      zcompile "$f" 2>/dev/null &!
    fi
  done
}

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# opencode
export PATH=/home/asif/.opencode/bin:$PATH
