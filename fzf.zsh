# =========================================================
# fzf Configuration
# =========================================================

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
elif command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --strip-cwd-prefix'
else
  export FZF_DEFAULT_COMMAND='find . -type f'
fi

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  [[ "$cmd" == "$FZF_DEFAULT_COMMAND" && "$cmd" == *"find "* ]] && cmd="find . -not -path '*/.*' -type f"
  result=$(eval "$cmd" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="${(q)result}"  # LBUFFER is the text left of cursor
  zle reset-prompt
}
zle -N _fzf_file_no_hidden

# =========================================================
# fzf-tab (Rich Contextual Fuzzy Completion)
# =========================================================

# Disable sort when completing git checkout
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# Populate LS_COLORS if unset so completion lists and fzf-tab use colors
if [[ -z "$LS_COLORS" ]] && command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi

# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Preview directory content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# Preview files with bat and directories with eza for argument completions
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  'if [[ -f $realpath ]]; then bat --color=always --style=plain,numbers --line-range=:300 $realpath; elif [[ -d $realpath ]]; then eza -1 --color=always $realpath; fi'

# Preview system processes when completing kill/pkill
zstyle ':fzf-tab:complete:(kill|pkill):*' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps -p "$word" -o command='
zstyle ':fzf-tab:complete:(kill|pkill):*' fzf-flags '--preview-window=down:3:wrap'

# Switch groups using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
