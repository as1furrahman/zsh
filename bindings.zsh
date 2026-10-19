# =========================================================
# Keybindings & Vi Mode
# =========================================================

# Cursor shape per vi mode
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# Reduce escape sequence delay from 400ms to 10ms for instant Vi mode switching
export KEYTIMEOUT=1

# zsh-vi-mode resets all bindings on init, so custom bindings
# must be registered via this hook to survive.
zvm_after_init() {
  # Re-source fzf key bindings so they survive zsh-vi-mode's keymap reset
  if [[ -n "$_FZF_SHELL_DIR" && -f "$_FZF_SHELL_DIR/key-bindings.zsh" ]]; then
    source "$_FZF_SHELL_DIR/key-bindings.zsh"
  elif command -v fzf >/dev/null 2>&1 && [[ -t 0 ]]; then
    eval "$(fzf --zsh 2>/dev/null)"
  fi

  # Restore fzf-tab's Tab completion in vi insert mode
  (( $+widgets[fzf-tab-complete] )) && bindkey -M viins '^I' fzf-tab-complete

  # Ctrl+Right -> move forward one word (^[[1;5C is the terminal escape code)
  bindkey '^[[1;5C' forward-word

  # Ctrl+Left -> move backward one word (^[[1;5D is the terminal escape code)
  bindkey '^[[1;5D' backward-word

  # Ctrl+F -> fzf file picker (no hidden files)
  bindkey '^F' _fzf_file_no_hidden

  # Ctrl+\ -> toggle autosuggestions (useful for screen recordings)
  bindkey '^\' autosuggest-toggle

  # Up/Down in insert mode -> history search by substring
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down

  # Normal mode (vicmd): Up/Down and k/j for substring search
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
  bindkey -M vicmd '^[[A' history-substring-search-up
  bindkey -M vicmd '^[[B' history-substring-search-down
}
