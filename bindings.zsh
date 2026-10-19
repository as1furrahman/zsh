# =========================================================
# Keybindings
# =========================================================

# Short escape-sequence delay (50 ms) that still survives multi-byte keys over SSH
export KEYTIMEOUT=5

# Applied once all plugins are loaded (.zshrc), or from zsh-vi-mode's init hook
# when ZSH_VI=1 (zsh-vi-mode resets every keymap on init).
_zsh_bindings() {
  local km
  _fzf_init keys

  for km in emacs viins; do
    # Restore fzf-tab's Tab completion
    (( $+widgets[fzf-tab-complete] )) && bindkey -M $km '^I' fzf-tab-complete

    # Ctrl+Right / Ctrl+Left -> move by word
    bindkey -M $km '^[[1;5C' forward-word
    bindkey -M $km '^[[1;5D' backward-word

    # Ctrl+F -> fzf file picker (no hidden files)
    bindkey -M $km '^F' _fzf_file_no_hidden

    # Ctrl+\ -> toggle autosuggestions (useful for screen recordings)
    (( $+widgets[autosuggest-toggle] )) && bindkey -M $km '^\' autosuggest-toggle

    # Up/Down -> history search by substring (normal and application cursor mode)
    if (( $+widgets[history-substring-search-up] )); then
      bindkey -M $km '^[[A' history-substring-search-up
      bindkey -M $km '^[[B' history-substring-search-down
      bindkey -M $km '^[OA' history-substring-search-up
      bindkey -M $km '^[OB' history-substring-search-down
    fi
  done
}

# Vi mode is opt-in (ZSH_VI=1): in normal mode a terminal paste is read as vi
# commands instead of text, which is never what you want from Ctrl+Shift+V.
if [[ -n $ZSH_VI ]]; then
  ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
  ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
  ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
  ZVM_VI_HIGHLIGHT_BACKGROUND=none
  ZVM_VI_HIGHLIGHT_FOREGROUND=none
  ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

  zvm_after_init() {
    _zsh_bindings
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
    bindkey -M vicmd '^[[A' history-substring-search-up
    bindkey -M vicmd '^[[B' history-substring-search-down
    bindkey -M vicmd '^[OA' history-substring-search-up
    bindkey -M vicmd '^[OB' history-substring-search-down
  }
fi
