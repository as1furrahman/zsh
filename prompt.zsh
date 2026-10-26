# ~/.config/zsh/prompt.zsh
# Pure native Zsh prompt adhering to suckless minimalism (zero external daemon forks)

# Prevent Python virtualenv from polluting the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

zmodload zsh/datetime zsh/mathfunc
autoload -Uz add-zsh-hook

# One color per directory level (256-color codes), cycled by depth
typeset -ga _prompt_colors=(111 114 179 176 209 80)
typeset -g _prompt_rc=0 _prompt_start=''

# Must run first: other precmd hooks (mise, zoxide) would overwrite $?
_prompt_rc_capture() { _prompt_rc=$? }

_prompt_preexec() { _prompt_start=$EPOCHREALTIME }

# DirA/DirB/DirC with a different color per level; long paths are shortened
_prompt_path() {
  local p=${PWD/#$HOME/\~} out='' name c i start=1
  local -a parts
  parts=( ${(s:/:)p} )

  if [[ $p == / ]]; then
    REPLY='%F{240}/%f'
    return
  fi
  (( $#parts > 5 )) && start=$(( $#parts - 3 ))

  [[ $p == /* ]] && out+='%F{240}/%f'
  (( start > 1 )) && out+='%F{240}…/%f'
  for (( i = start; i <= $#parts; i++ )); do
    c=${_prompt_colors[$(( (i - 1) % $#_prompt_colors + 1 ))]}
    name=${parts[i]//\%/%%}
    if (( i == $#parts )); then
      out+="%B%F{$c}${name}%f%b"
    else
      out+="%F{$c}${name}%f%F{240}/%f"
    fi
  done
  REPLY=$out
}

# repo name, branch, staged/modified/untracked/conflict counts, ahead/behind
_prompt_git() {
  REPLY=''
  local top status_out line head='' oid='' ab ahead=0 behind=0
  local -i staged=0 dirty=0 untracked=0 conflict=0
  top=$(command git rev-parse --show-toplevel 2>/dev/null) || return
  status_out=$(GIT_OPTIONAL_LOCKS=0 command timeout 1 git status --porcelain=v2 --branch 2>/dev/null)

  for line in ${(f)status_out}; do
    case $line in
      '# branch.oid '*)  oid=${line#\# branch.oid } ;;
      '# branch.head '*) head=${line#\# branch.head } ;;
      '# branch.ab '*)
        ab=${line#\# branch.ab }
        ahead=${${ab%% *}#+}
        behind=${${ab##* }#-}
        ;;
      '1 '*|'2 '*)
        [[ ${line[3]} != . ]] && (( staged++ ))
        [[ ${line[4]} != . ]] && (( dirty++ ))
        ;;
      'u '*) (( conflict++ )) ;;
      '? '*) (( untracked++ )) ;;
    esac
  done

  [[ $head == '(detached)' ]] && head=${oid[1,7]}
  local repo=${top:t}
  REPLY="%F{245} ${repo//\%/%%}%f %F{111} ${head//\%/%%}%f"
  (( staged ))    && REPLY+=" %F{114}+${staged}%f"
  (( dirty ))     && REPLY+=" %F{179}!${dirty}%f"
  (( untracked )) && REPLY+=" %F{176}?${untracked}%f"
  (( conflict ))  && REPLY+=" %F{203}=${conflict}%f"
  (( ahead ))     && REPLY+=" %F{80}⇡${ahead}%f"
  (( behind ))    && REPLY+=" %F{209}⇣${behind}%f"
}

_prompt_precmd() {
  local took='' status_seg
  if [[ -n $_prompt_start ]]; then
    local -i s=$(( int(EPOCHREALTIME - _prompt_start) ))
    _prompt_start=''
    if (( s >= 2 )); then
      (( s >= 3600 )) && took+="$(( s / 3600 ))h"
      (( s >= 60 ))   && took+="$(( s % 3600 / 60 ))m"
      took+="$(( s % 60 ))s"
    fi
  fi

  _prompt_path;  local dir=$REPLY
  _prompt_git;   local git=$REPLY

  if (( _prompt_rc )); then
    status_seg="%F{203}✘ ${_prompt_rc}%f"
    local char='%F{203}❯%f'
  else
    status_seg='%F{114}✔%f'
    local char='%F{114}❯%f'
  fi

  PROMPT="${dir}${git}"$'\n'"${char} "
  local took_seg=''
  [[ -n $took ]] && took_seg="%F{180}󱎫 ${took}%f "
  RPROMPT="${took_seg}${status_seg} %F{240}%D{%H:%M:%S}%f"
}

# rc capture first, builder last
precmd_functions=( _prompt_rc_capture ${precmd_functions:#_prompt_rc_capture} )
add-zsh-hook precmd _prompt_precmd
add-zsh-hook preexec _prompt_preexec
