# ~/.config/zsh/.zshenv

# ---------- Deduplicate PATH and path array ----------
# In Zsh, scalar $PATH and array $path are linked. Setting -U ensures
# every entry is unique, preventing duplicates across subshells.
typeset -U PATH path

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
[[ -t 0 ]] && export GPG_TTY=$(tty)

# ---------- Starship ----------
# $ZDOTDIR is exported by /etc/zsh/zshenv; fall back anyway so the path can
# never collapse to the literal "/starship.toml" if that block is missing.
export STARSHIP_CONFIG="${ZDOTDIR:-$HOME/.config/zsh}/starship.toml"

# ---------- Completion Optimization ----------
# Ubuntu's /etc/zsh/zshrc runs compinit unless this is set; .zshrc runs it again
# with a cache and a 20-hour audit guard. Stand the system one down so there is
# one dump to build and one directory scan at startup, not two.
skip_global_compinit=1

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"

# ---------- Docker / Podman Compatibility ----------
if [[ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock" ]]; then
  export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
fi
