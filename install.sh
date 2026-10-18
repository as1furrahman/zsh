#!/usr/bin/env bash
#
# Zsh Configuration Installer for Arch, Fedora & Ubuntu / Debian
# Sets up dependencies, XDG directory structure, system /etc/zsh/zshenv,
# and links/compiles the Zsh configuration.
#
# Usage:
#   ./install.sh             # Full automated reproduction (interactive prompts for sudo/chsh)
#   ./install.sh --all       # Run everything (deps + config + system + shell)
#   ./install.sh --deps      # Install distro packages, starship, zoxide & CLI symlinks
#   ./install.sh --config    # Link user configurations to ~/.config/zsh
#   ./install.sh --system    # Install /etc/zsh/zshenv (requires root/sudo)
#   ./install.sh --shell     # Change user default login shell to zsh
#   ./install.sh --dry-run   # Preview actions without modifying anything
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${ZSH_INSTALL_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-backups/$(date +%Y%m%d_%H%M%S)"

DRY_RUN=false
DO_DEPS=false
DO_CONFIG=false
DO_SYSTEM=false
DO_SHELL=false

# Terminal colors
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN=''
  BLUE=''
  YELLOW=''
  RED=''
  BOLD=''
  NC=''
fi

log_info()    { printf "%b[INFO]%b %s\n" "$BLUE" "$NC" "$*"; }
log_ok()      { printf "%b[OK]%b %s\n" "$GREEN" "$NC" "$*"; }
log_warn()    { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$*"; }
log_err()     { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$*" >&2; }
log_action()  { printf "%b==> %s%b\n" "$BOLD" "$*" "$NC"; }

run_as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}:${ID_LIKE:-}" in
      *arch*|*manjaro*|*endeavouros*)
        echo "arch"
        ;;
      *fedora*|*rhel*|*centos*)
        echo "fedora"
        ;;
      *ubuntu*|*debian*|*pop*|*mint*)
        echo "debian"
        ;;
      *)
        echo "unknown"
        ;;
    esac
  elif command -v pacman >/dev/null 2>&1; then
    echo "arch"
  elif command -v dnf >/dev/null 2>&1; then
    echo "fedora"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "debian"
  else
    echo "unknown"
  fi
}

usage() {
  cat <<EOF
Zsh Configuration Installer (Arch, Fedora & Ubuntu / Debian)

USAGE:
  ./install.sh [OPTIONS]

OPTIONS:
  --all         Install dependencies, link configuration, set up system zshenv, and change shell
  --deps        Install distro packages (zsh, neovim, eza, bat, fd, fzf, ripgrep, starship, zoxide)
  --config      Link/install configuration files to ~/.config/zsh
  --system      Install system Zsh redirection to ~/.config/zsh (requires root/sudo)
  --shell       Set zsh as the default login shell via chsh
  -n, --dry-run Preview changes without modifying files or system state
  -h, --help    Show this help message

If no option is provided, --all will be executed.
EOF
}

# Guard against accidentally running under sudo
if [[ "${EUID:-$(id -u)}" -eq 0 ]] && [[ -n "${SUDO_USER:-}" ]]; then
  log_err "Do not run install.sh with sudo directly (invoked via sudo by $SUDO_USER)."
  log_err "Run as your regular user: ./install.sh"
  log_err "The script requests sudo permissions internally when installing system files."
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      DO_DEPS=true
      DO_CONFIG=true
      DO_SYSTEM=true
      DO_SHELL=true
      ;;
    --deps)
      DO_DEPS=true
      ;;
    --config)
      DO_CONFIG=true
      ;;
    --system)
      DO_SYSTEM=true
      ;;
    --shell)
      DO_SHELL=true
      ;;
    -n|--dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

# If no specific action was selected, default to all
if ! $DO_DEPS && ! $DO_CONFIG && ! $DO_SYSTEM && ! $DO_SHELL; then
  DO_DEPS=true
  DO_CONFIG=true
  DO_SYSTEM=true
  DO_SHELL=true
fi

backup_if_exists() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    if $DRY_RUN; then
      log_info "Would backup: $target -> $BACKUP_DIR"
    else
      mkdir -p "$BACKUP_DIR"
      mv "$target" "$BACKUP_DIR/"
      log_ok "Backed up existing $target -> $BACKUP_DIR/"
    fi
  fi
}

install_deps() {
  local distro
  distro="$(detect_distro)"
  log_action "Installing packages & dependencies for $distro Linux..."

  case "$distro" in
    arch)
      if $DRY_RUN; then
        log_info "Would run: pacman -S --needed --noconfirm zsh neovim eza bat fd fzf ripgrep git curl starship zoxide"
      else
        log_info "Installing dependencies via pacman..."
        run_as_root pacman -S --needed --noconfirm zsh neovim eza bat fd fzf ripgrep git curl starship zoxide
      fi
      ;;
    fedora)
      if $DRY_RUN; then
        log_info "Would run: dnf install -y zsh neovim eza bat fd-find fzf ripgrep git curl starship zoxide"
      else
        log_info "Installing dependencies via dnf..."
        run_as_root dnf install -y zsh neovim eza bat fd-find fzf ripgrep git curl starship zoxide
      fi
      ;;
    debian)
      if $DRY_RUN; then
        log_info "Would run: apt update && apt install -y zsh neovim eza bat fd-find fzf ripgrep git curl"
      else
        log_info "Installing dependencies via apt..."
        run_as_root apt update -y
        if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
          DEBIAN_FRONTEND=noninteractive apt install -y zsh neovim eza bat fd-find fzf ripgrep git curl
        else
          sudo DEBIAN_FRONTEND=noninteractive apt install -y zsh neovim eza bat fd-find fzf ripgrep git curl
        fi
      fi
      ;;
    *)
      log_warn "Unknown Linux distribution. Skipping automatic package manager installation."
      log_info "Please ensure the following tools are installed: zsh neovim eza bat fd fzf ripgrep starship zoxide"
      ;;
  esac

  # Ensure ~/.local/bin exists in PATH
  mkdir -p "$HOME/.local/bin"

  # Distros packaging bat as batcat (Debian/Ubuntu)
  local batcat_bin
  batcat_bin="$(command -v batcat || true)"
  if [[ -n "$batcat_bin" && ! -e "$HOME/.local/bin/bat" && ! -L "$HOME/.local/bin/bat" ]]; then
    if ! command -v bat >/dev/null 2>&1; then
      if $DRY_RUN; then
        log_info "Would symlink $HOME/.local/bin/bat -> $batcat_bin"
      else
        ln -sf "$batcat_bin" "$HOME/.local/bin/bat"
        log_ok "Symlinked ~/.local/bin/bat -> $batcat_bin"
      fi
    fi
  fi

  # Distros packaging fd as fdfind (Debian/Ubuntu/Fedora)
  local fdfind_bin
  fdfind_bin="$(command -v fdfind || true)"
  if [[ -n "$fdfind_bin" && ! -e "$HOME/.local/bin/fd" && ! -L "$HOME/.local/bin/fd" ]]; then
    if ! command -v fd >/dev/null 2>&1; then
      if $DRY_RUN; then
        log_info "Would symlink $HOME/.local/bin/fd -> $fdfind_bin"
      else
        ln -sf "$fdfind_bin" "$HOME/.local/bin/fd"
        log_ok "Symlinked ~/.local/bin/fd -> $fdfind_bin"
      fi
    fi
  fi

  # starship & zoxide are installed by the distro packages above; never pipe
  # a remote script into a shell, just tell the user what is missing.
  local tool
  for tool in starship zoxide; do
    if command -v "$tool" >/dev/null 2>&1; then
      log_ok "$tool is already installed"
    else
      log_warn "$tool not found; install it with your package manager (https://starship.rs, https://github.com/ajeetdsouza/zoxide)"
    fi
  done
}

install_config() {
  log_action "Configuring user files ($TARGET_DIR)..."

  # Ensure state and cache directories exist
  if ! $DRY_RUN; then
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    mkdir -p "$TARGET_DIR"
  fi

  # If repo is already located at TARGET_DIR, we don't need to symlink internally
  if [[ "$SCRIPT_DIR" == "$TARGET_DIR" ]]; then
    log_ok "Repository is already located at $TARGET_DIR"
  else
    local files=(
      ".zshenv"
      ".zshrc"
      "aliases.zsh"
      "bindings.zsh"
      "fzf.zsh"
      "plugins.zsh"
      "plugins.lock"
      "prompt.zsh"
      "starship.toml"
      ".gitignore"
      "LICENSE"
    )

    for file in "${files[@]}"; do
      local src="$SCRIPT_DIR/$file"
      local dest="$TARGET_DIR/$file"

      if [[ -f "$src" ]]; then
        if [[ -L "$dest" && "$(readlink -- "$dest")" == "$src" ]]; then
          log_ok "Already linked: $file"
          continue
        fi

        backup_if_exists "$dest"

        if $DRY_RUN; then
          log_info "Would link: $dest -> $src"
        else
          ln -snf "$src" "$dest"
          log_ok "Linked: $dest -> $src"
        fi
      fi
    done
  fi

  # Install plugins at the exact commits pinned in plugins.lock
  local plugin_dir="$TARGET_DIR/plugins"
  local lock="$SCRIPT_DIR/plugins.lock"
  if command -v git >/dev/null 2>&1 && [[ -f "$lock" ]] && ! $DRY_RUN; then
    mkdir -p "$plugin_dir"
    local p_owner p_name p_sha p_dest
    while read -r p_owner p_name p_sha; do
      [[ -z "$p_owner" || "$p_owner" == \#* ]] && continue
      p_dest="$plugin_dir/$p_name"
      if [[ -d "$p_dest" ]]; then
        log_ok "Plugin $p_name is already installed"
        continue
      fi
      log_info "Installing plugin $p_name @ ${p_sha:0:7}..."
      if git init -q "$p_dest" \
        && git -C "$p_dest" remote add origin "https://github.com/$p_owner/$p_name" \
        && git -C "$p_dest" fetch -q --depth=1 origin "$p_sha" \
        && git -C "$p_dest" checkout -q FETCH_HEAD; then
        log_ok "Installed $p_name"
      else
        rm -rf "$p_dest"
        log_warn "Could not install $p_name; re-run ./install.sh --config when online"
      fi
    done < "$lock"
  fi

  # Pre-compile bytecode for instant startup
  if command -v zsh >/dev/null 2>&1 && ! $DRY_RUN; then
    log_info "Compiling bytecode (.zwc)..."
    for f in "$TARGET_DIR"/.zshrc "$TARGET_DIR"/.zshenv "$TARGET_DIR"/*.zsh; do
      if [[ -f "$f" ]]; then
        zsh -c "zcompile '$f'" 2>/dev/null || true
      fi
    done
    for f in "$plugin_dir"/*/*.plugin.zsh "$plugin_dir"/*/*.zsh; do
      if [[ -f "$f" ]]; then
        zsh -c "zcompile '$f'" 2>/dev/null || true
      fi
    done
    log_ok "Bytecode compiled"
  fi
}

install_system() {
  log_action "Installing system Zsh redirection..."
  local sys_src="$SCRIPT_DIR/system/etc/zsh/zshenv"
  local dest_zsh="/etc/zsh/zshenv"
  local dest_etc="/etc/zshenv"

  if [[ ! -f "$sys_src" ]]; then
    log_err "Missing $sys_src"
    return 1
  fi

  # Support both /etc/zsh/zshenv (Debian/Ubuntu/Arch) and /etc/zshenv (Fedora/RHEL)
  local targets=()
  targets+=("$dest_zsh")
  local distro
  distro="$(detect_distro)"
  if [[ "$distro" == "fedora" || -f "$dest_etc" ]]; then
    targets+=("$dest_etc")
  fi

  for target in "${targets[@]}"; do
    if cmp -s "$sys_src" "$target" 2>/dev/null; then
      log_ok "$target is already up to date"
      continue
    fi

    if $DRY_RUN; then
      log_info "Would copy $sys_src -> $target (root)"
    else
      run_as_root mkdir -p "$(dirname "$target")"
      if [[ -f "$target" ]]; then
        run_as_root cp -a "$target" "${target}.bak.$(date +%Y%m%d_%H%M%S)"
        log_ok "Backed up existing $target"
      fi
      run_as_root install -m 0644 -o root -g root "$sys_src" "$target"
      log_ok "Installed $target (root:root 0644)"
    fi
  done
}

set_default_shell() {
  local zsh_bin
  zsh_bin="$(command -v zsh || true)"
  if [[ -z "$zsh_bin" ]]; then
    log_warn "zsh is not installed; skipping shell change"
    return 0
  fi

  local current_user="${USER:-$(id -un 2>/dev/null || whoami 2>/dev/null || echo "root")}"
  local current_shell
  current_shell="$(getent passwd "$current_user" 2>/dev/null | cut -d: -f7 || grep "^$current_user:" /etc/passwd 2>/dev/null | cut -d: -f7 || echo "${SHELL:-}")"
  if [[ "$current_shell" == "$zsh_bin" ]]; then
    log_ok "Default shell is already $zsh_bin"
    return 0
  fi

  log_action "Changing default shell to $zsh_bin..."
  if $DRY_RUN; then
    log_info "Would run: chsh -s $zsh_bin $current_user"
  else
    if command -v chsh >/dev/null 2>&1; then
      if ! chsh -s "$zsh_bin" "$current_user"; then
        log_warn "Automatic chsh failed. Run manually: chsh -s $zsh_bin"
      else
        log_ok "Changed default shell to $zsh_bin (takes effect on next login)"
      fi
    elif [[ -f /etc/passwd ]] && [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
      # Fallback in minimal containers without chsh
      sed -i -E "s|^(${current_user}:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*):.*$|\1:${zsh_bin}|" /etc/passwd 2>/dev/null || true
      log_ok "Updated default shell in /etc/passwd to $zsh_bin"
    fi
  fi
}

main() {
  printf '\n%b================================================%b\n' "$BOLD" "$NC"
  printf '%b   Zsh Reproducible Environment Setup          %b\n' "$BOLD" "$NC"
  printf '%b================================================%b\n\n' "$BOLD" "$NC"

  $DO_DEPS && install_deps
  $DO_CONFIG && install_config
  $DO_SYSTEM && install_system
  $DO_SHELL && set_default_shell

  printf '\n%b%b✔ Setup completed successfully!%b\n' "$GREEN" "$BOLD" "$NC"
  printf 'To start using your new configuration, simply launch:\n'
  printf '    %bexec zsh%b\n\n' "$BOLD" "$NC"
}

main
