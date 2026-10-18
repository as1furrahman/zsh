#!/usr/bin/env bash
#
# Zsh Configuration Installer for Ubuntu 26.04.1 LTS
# Sets up dependencies, XDG directory structure, system /etc/zsh/zshenv,
# and links/compiles the Zsh configuration.
#
# Usage:
#   ./install.sh             # Full automated reproduction (interactive prompts for sudo/chsh)
#   ./install.sh --all       # Run everything (deps + config + system + shell)
#   ./install.sh --deps      # Install apt dependencies, starship, zoxide & CLI symlinks
#   ./install.sh --config    # Link user configurations to ~/.config/zsh
#   ./install.sh --system    # Install /etc/zsh/zshenv (requires sudo)
#   ./install.sh --shell     # Change user default login shell to zsh
#   ./install.sh --dry-run   # Preview actions without modifying anything
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
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

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_ok()      { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_err()     { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
log_action()  { printf "${BOLD}==> %s${NC}\n" "$*"; }

usage() {
  cat <<EOF
${BOLD}Zsh Configuration Installer (Ubuntu 26.04.1 LTS)${NC}

${BOLD}USAGE:${NC}
  ./install.sh [OPTIONS]

${BOLD}OPTIONS:${NC}
  --all         Install dependencies, link configuration, set up system zshenv, and change shell
  --deps        Install Ubuntu packages (zsh, neovim, eza, bat, fd, fzf, ripgrep, starship, zoxide)
  --config      Link/install configuration files to ~/.config/zsh
  --system      Install /etc/zsh/zshenv to redirect ZDOTDIR to ~/.config/zsh (requires sudo)
  --shell       Set zsh as the default login shell via chsh
  -n, --dry-run Preview changes without modifying files or system state
  -h, --help    Show this help message

If no option is provided, --all will be executed.
EOF
}

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
  log_action "Installing Ubuntu packages & dependencies..."

  if $DRY_RUN; then
    log_info "Would run: sudo apt update && sudo apt install -y zsh neovim eza bat fd-find fzf ripgrep git curl"
  else
    log_info "Checking sudo access..."
    sudo apt update -y
    sudo apt install -y zsh neovim eza bat fd-find fzf ripgrep git curl
  fi

  # Ensure ~/.local/bin exists in PATH
  mkdir -p "$HOME/.local/bin"

  # Ubuntu packages bat as batcat and fd as fdfind; create compat symlinks
  local batcat_bin
  batcat_bin="$(command -v batcat || true)"
  if [[ -n "$batcat_bin" && ! -e "$HOME/.local/bin/bat" ]]; then
    if $DRY_RUN; then
      log_info "Would symlink $HOME/.local/bin/bat -> $batcat_bin"
    else
      ln -sf "$batcat_bin" "$HOME/.local/bin/bat"
      log_ok "Symlinked ~/.local/bin/bat -> $batcat_bin"
    fi
  fi

  local fdfind_bin
  fdfind_bin="$(command -v fdfind || true)"
  if [[ -n "$fdfind_bin" && ! -e "$HOME/.local/bin/fd" ]]; then
    if $DRY_RUN; then
      log_info "Would symlink $HOME/.local/bin/fd -> $fdfind_bin"
    else
      ln -sf "$fdfind_bin" "$HOME/.local/bin/fd"
      log_ok "Symlinked ~/.local/bin/fd -> $fdfind_bin"
    fi
  fi

  # Starship prompt installation
  if ! command -v starship >/dev/null 2>&1; then
    log_action "Installing Starship prompt..."
    if $DRY_RUN; then
      log_info "Would run: curl -sS https://starship.rs/install.sh | sh -s -- -y"
    else
      curl -sS https://starship.rs/install.sh | sh -s -- -y
      log_ok "Starship installed successfully"
    fi
  else
    log_ok "Starship is already installed"
  fi

  # Zoxide installation
  if ! command -v zoxide >/dev/null 2>&1; then
    log_action "Installing zoxide..."
    if $DRY_RUN; then
      log_info "Would run: curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"
    else
      curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
      log_ok "Zoxide installed successfully"
    fi
  else
    log_ok "Zoxide is already installed"
  fi
}

install_config() {
  log_action "Configuring user files (~/.config/zsh)..."

  # Ensure state and cache directories exist
  if ! $DRY_RUN; then
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    mkdir -p "$TARGET_DIR"
  fi

  # If repo is already located at ~/.config/zsh, we don't need to symlink internally
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
      "prompt.zsh"
      "starship.toml"
      ".gitignore"
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

  # Pre-compile bytecode for instant startup
  if command -v zsh >/dev/null 2>&1 && ! $DRY_RUN; then
    log_info "Compiling bytecode (.zwc)..."
    for f in "$TARGET_DIR"/.zshrc "$TARGET_DIR"/.zshenv "$TARGET_DIR"/*.zsh; do
      if [[ -f "$f" ]]; then
        zsh -c "zcompile '$f'" 2>/dev/null || true
      fi
    done
    log_ok "Bytecode compiled"
  fi
}

install_system() {
  log_action "Installing system /etc/zsh/zshenv..."
  local sys_src="$SCRIPT_DIR/system/etc/zsh/zshenv"
  local sys_dest="/etc/zsh/zshenv"

  if [[ ! -f "$sys_src" ]]; then
    log_err "Missing $sys_src"
    return 1
  fi

  if cmp -s "$sys_src" "$sys_dest" 2>/dev/null; then
    log_ok "/etc/zsh/zshenv is already up to date"
    return 0
  fi

  if $DRY_RUN; then
    log_info "Would copy $sys_src -> $sys_dest (sudo)"
  else
    if [[ -f "$sys_dest" ]]; then
      sudo cp -a "$sys_dest" "${sys_dest}.bak.$(date +%Y%m%d_%H%M%S)"
      log_ok "Backed up existing $sys_dest"
    fi
    sudo install -m 0644 -o root -g root "$sys_src" "$sys_dest"
    log_ok "Installed /etc/zsh/zshenv (root:root 0644)"
  fi
}

set_default_shell() {
  local zsh_bin
  zsh_bin="$(command -v zsh || true)"
  if [[ -z "$zsh_bin" ]]; then
    log_warn "zsh is not installed; skipping shell change"
    return 0
  fi

  local current_shell
  current_shell="$(grep "^$USER:" /etc/passwd | cut -d: -f7)"
  if [[ "$current_shell" == "$zsh_bin" ]]; then
    log_ok "Default shell is already $zsh_bin"
    return 0
  fi

  log_action "Changing default shell to $zsh_bin..."
  if $DRY_RUN; then
    log_info "Would run: chsh -s $zsh_bin $USER"
  else
    chsh -s "$zsh_bin" "$USER"
    log_ok "Changed default shell to $zsh_bin (takes effect on next login)"
  fi
}

main() {
  printf "\n${BOLD}================================================${NC}\n"
  printf "${BOLD}   Zsh Reproducible Environment Setup          ${NC}\n"
  printf "${BOLD}================================================${NC}\n\n"

  $DO_DEPS && install_deps
  $DO_CONFIG && install_config
  $DO_SYSTEM && install_system
  $DO_SHELL && set_default_shell

  printf "\n${GREEN}${BOLD}✔ Setup completed successfully!${NC}\n"
  printf "To start using your new configuration, simply launch:\n"
  printf "    ${BOLD}exec zsh${NC}\n\n"
}

main
