# Powerful but tastefully minimal zsh configuration
# Tailored for Ubuntu 26.04.1 LTS & XDG Base Directory specification

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
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt EXTENDED_HISTORY         # Record timestamp (epoch) and execution duration
setopt INC_APPEND_HISTORY_TIME  # Append immediately upon command exit with execution time
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks from history commands

# =========================================================
# Shell Behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT       # Sort file10 after file9, not after file1
setopt EXTENDED_GLOB           # Enable advanced zsh glob qualifiers and patterns
setopt AUTO_PUSHD              # Make cd push old directory to stack
setopt PUSHD_IGNORE_DUPS       # Don't push duplicate directories to stack
setopt PUSHD_SILENT            # Don't print directory stack after pushd/popd

# =========================================================
# Smart Directory Navigation & Tools
# =========================================================

if [[ -f ~/.config/lf/icons ]]; then
  LF_ICONS=$(cat ~/.config/lf/icons | tr '\n' ':')
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
if [[ -n "$_zcompdump"(#qN.mh-20) ]]; then
  compinit -C -d "$_zcompdump"
else
  compinit -d "$_zcompdump"
  { zcompile "$_zcompdump" } >/dev/null 2>&1 &!
fi
unset _zcompdump

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Make completion case-insensitive (doc matches Documents)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# =========================================================
# Fuzzy Finder (fzf key-bindings and completion)
# =========================================================

for _fzf_script in \
  /opt/homebrew/opt/fzf/shell \
  /usr/local/opt/fzf/shell \
  /usr/share/fzf \
  /usr/share/doc/fzf/examples \
  "$HOME/.fzf/shell"; do
  if [[ -f "$_fzf_script/key-bindings.zsh" ]]; then
    source "$_fzf_script/key-bindings.zsh"
    [[ -f "$_fzf_script/completion.zsh" ]] && source "$_fzf_script/completion.zsh"
    break
  fi
done
unset _fzf_script

# =========================================================
# Modular Config Modules
# =========================================================

source "$ZDOTDIR/fzf.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/plugins.zsh"
source "$ZDOTDIR/prompt.zsh"

# =========================================================
# Node (nvm) - Instant Fast-Path & Lazy Loader
# =========================================================

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ -d "$NVM_DIR/versions/node" ]]; then
  _has_default=0
  _v=''
  if [[ -r "$NVM_DIR/alias/default" ]]; then
    _has_default=1
    _v="$(< "$NVM_DIR/alias/default")"
  fi

  _seen=" :$_v:"
  while [[ -n "$_v" && -r "$NVM_DIR/alias/$_v" ]]; do
    _next="$(< "$NVM_DIR/alias/$_v")"
    [[ $_seen == *":$_next:"* ]] && break
    _v="$_next"
    _seen="$_seen$_v:"
  done
  unset _seen _next
  _v="${_v#v}"

  _bin=''
  if [[ "$_v" == "system" ]]; then
    : # Preserve system node selection
  else
    # When fast path cannot resolve the configured alias, load nvm to resolve it
    if [[ "$_v" == */* || ( -n "$_v" && ! "$_v" =~ ^[0-9] ) ]]; then
      if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        . "$NVM_DIR/nvm.sh" --no-use 2>/dev/null
        _resolved="$(nvm_resolve_alias "${_v:-default}" 2>/dev/null)"
        _resolved="${_resolved#v}"
        if [[ "$_resolved" == "system" ]]; then
          _v="system"
        elif [[ "$_resolved" =~ ^[0-9] ]]; then
          _v="$_resolved"
        else
          _v=''
        fi
        unset _resolved
      fi
    fi

    if [[ "$_v" == "system" ]]; then
      : # Preserve system node selection
    elif [[ -n "$_v" ]]; then
      for _d in "$NVM_DIR"/versions/node/v${_v}(|.*)/bin(Nn); do _bin=$_d; done
    elif (( ! _has_default )); then
      for _d in "$NVM_DIR"/versions/node/*/bin(Nn); do _bin=$_d; done
    fi

    if [[ -n $_bin ]]; then
      case ":$PATH:" in
        *":$_bin:"*) ;;
        *) PATH="$_bin:$PATH" ;;
      esac
    fi
  fi
  unset _has_default _v _bin _d
fi
export PATH

# Load real nvm on first use
if [[ -s "$NVM_DIR/nvm.sh" ]] && (( ! $+functions[nvm] )); then
  nvm() {
    unfunction nvm
    . "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
    rehash
    nvm "$@"
  }
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
