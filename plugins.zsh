# =========================================================
# Plugins & Automated Manager
# =========================================================

ZPLUGINDIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
ZPLUGINLOCK="${ZDOTDIR:-$HOME/.config/zsh}/plugins.lock"
typeset -ga _zplugin_missing=()

# Source a plugin that ./install.sh --config installed at its pinned commit.
# Never clones: shell startup must not touch the network or run fetched code.
_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  local plugin_file="${plugin_path}/${2}.plugin.zsh"
  [[ -f "$plugin_file" ]] || plugin_file="${plugin_path}/${2}.zsh"

  if [[ ! -f "$plugin_file" ]]; then
    _zplugin_missing+=("$2")
    return 1
  fi

  # Bytecode compile if missing or modified
  if [[ ! -f "${plugin_file}.zwc" || "$plugin_file" -nt "${plugin_file}.zwc" ]]; then
    zcompile "$plugin_file" 2>/dev/null
  fi
  source "$plugin_file"
}

# Compare each installed plugin with upstream HEAD. With --apply, check out the
# upstream commit and print the plugins.lock line to commit.
zplugin-update() {
  local apply=0 owner name sha dir current remote
  [[ "$1" == --apply ]] && apply=1

  while read -r owner name sha; do
    [[ -z "$owner" || "$owner" == \#* ]] && continue
    dir="${ZPLUGINDIR}/${name}"
    if [[ ! -d "$dir" ]]; then
      echo "${name}: not installed"
      continue
    fi
    current="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
    remote="$(git -C "$dir" ls-remote origin HEAD 2>/dev/null | cut -f1)"
    if [[ -z "$remote" ]]; then
      echo "${name}: cannot reach upstream"
    elif [[ "$remote" == "$current" ]]; then
      echo "${name}: up to date (${current[1,7]})"
    elif (( apply )); then
      git -C "$dir" fetch -q --depth=1 origin "$remote" \
        && git -C "$dir" checkout -q FETCH_HEAD \
        && rm -f "${dir}"/*.zwc(N) \
        && echo "${name}: updated ${current[1,7]} -> ${remote[1,7]}   lock: ${owner} ${name} ${remote}"
    else
      echo "${name}: upstream is ${remote[1,7]}, installed ${current[1,7]} (run zplugin-update --apply)"
    fi
  done < "$ZPLUGINLOCK"
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

(( $#_zplugin_missing )) && print -u2 "zsh: missing plugins (${_zplugin_missing}); run ./install.sh --config"
