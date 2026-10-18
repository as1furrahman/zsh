# =========================================================
# Plugins & Automated Manager
# =========================================================

ZPLUGINDIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"

_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  local plugin_file="${plugin_path}/${2}.plugin.zsh"
  [[ -f "$plugin_file" ]] || plugin_file="${plugin_path}/${2}.zsh"

  if [[ ! -d "$plugin_path" || ! -f "$plugin_file" ]]; then
    mkdir -p "$ZPLUGINDIR"
    rm -rf "$plugin_path"
    echo "Installing ${2}..."
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; rm -rf "$plugin_path"; return 1; }
    [[ -f "$plugin_file" ]] || plugin_file="${plugin_path}/${2}.zsh"
  fi

  if [[ -f "$plugin_file" ]]; then
    # Bytecode compile if missing or modified
    if [[ ! -f "${plugin_file}.zwc" || "$plugin_file" -nt "${plugin_file}.zwc" ]]; then
      zcompile "$plugin_file" 2>/dev/null
    fi
    source "$plugin_file"
    return 0
  fi
  return 1
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
    # (N) nullglob: if no .zwc exists, expands to nothing rather than failing
    rm -f "${dir}"*.zwc(N) 2>/dev/null
  done
}

# 1. Interactive fuzzy tab completion (must load before syntax-highlighting & autosuggestions)
if _zplugin_load Aloxaf fzf-tab; then
  # Disable native completion menu only when fzf-tab is successfully active
  zstyle ':completion:*' menu no
fi

# 2. Syntax highlighting & line suggestions
_zplugin_load zdharma-continuum fast-syntax-highlighting

# Zero-latency asynchronous autosuggestions (never blocks keystrokes)
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200
_zplugin_load zsh-users zsh-autosuggestions
_zplugin_load zsh-users zsh-history-substring-search

# 3. Vi mode
_zplugin_load jeffreytse zsh-vi-mode
