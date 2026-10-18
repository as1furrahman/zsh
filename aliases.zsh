# Better ls via eza
alias ls='eza --icons auto'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons auto --git'

# Tree view
alias tree='eza --tree --icons auto'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat, kept pipe- and script-safe: no decoration, no pager
alias cat='bat --style=plain --paging=never'

# =========================================================
# Core utilities
# =========================================================

alias grep='grep --color=auto'
alias r='rg'
alias rgi='rg -i'
alias diff='diff --color=auto'
alias df='df -h'

# =========================================================
# Navigation
# =========================================================

alias -- -='cd -'            # cd - jumps to previous directory
alias d='dirs -v | head -10'  # Show directory stack

# Positive indices so typed number matches dirs -v output
setopt NO_PUSHD_MINUS
alias 1='cd +1'
alias 2='cd +2'
alias 3='cd +3'
alias 4='cd +4'

# lf integration (terminal file manager directory following)
lf() {
  local tmp dir
  tmp=$(mktemp)
  command lf -last-dir-path="$tmp" "$@"
  if [ -f "$tmp" ]; then
    dir=$(< "$tmp")
    rm -f "$tmp"
    [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
  fi
}

# =========================================================
# Editor
# =========================================================

alias vim='nvim'

# =========================================================
# Git
# =========================================================

alias glog='PAGER="less -F -X" git log'
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git -C "$HOME/Projects/dotfile"'

# =========================================================
# Video / Streaming
# =========================================================

# Guarded: only register stream alias if mpv is installed
if command -v mpv >/dev/null 2>&1; then
  alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'
fi
