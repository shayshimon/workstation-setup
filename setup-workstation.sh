#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# WORKSTATION SETUP SCRIPT
# ============================================================================
# Idempotent macOS dev-machine bootstrap.
# Safe to re-run: installs missing tools, links dotfiles with timestamped
# backups, and appends shell config only when needed.
# ============================================================================

# ----------------------------------------------------------------------------
# CONFIGURATION - Toggle features on/off
# ----------------------------------------------------------------------------
INSTALL_HOMEBREW=true
INSTALL_GHOSTTY=true
INSTALL_ZSH_PLUGINS=true
INSTALL_STARSHIP=true
INSTALL_CLI_TOOLS=true
INSTALL_FZF_LINE_ADDED=false
INSTALL_UV=true
INSTALL_NODE=true
INSTALL_NEOVIM=true
INSTALL_TMUX=true
INSTALL_AWS=true
INSTALL_DB=true
INSTALL_GIT_TOOLS=true
INSTALL_FONT=true
LINK_DOTFILES=true
CONFIGURE_SHELL=true
CONFIGURE_GIT=true

PYTHON_VERSION="3.12"
NVM_VERSION="v0.40.4"

# Where this script and dotfiles live
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

# ----------------------------------------------------------------------------
# HELPERS
# ----------------------------------------------------------------------------
info() { printf "\033[1;34m=> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32mOK %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m!! %s\033[0m\n" "$1"; }
err()  { printf "\033[1;31mXX %s\033[0m\n" "$1"; }

ensure_homebrew_on_path() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

brew_install() {
    local formula="$1"

    if brew list --formula "$formula" >/dev/null 2>&1; then
        ok "$formula already installed"
    else
        info "Installing $formula..."
        brew install "$formula"
    fi
}

brew_cask_install() {
    local cask="$1"
    local existing_path="${2:-}"

    if brew list --cask "$cask" >/dev/null 2>&1; then
        ok "$cask cask already installed"
    elif [ -n "$existing_path" ] && [ -e "$existing_path" ]; then
        warn "$cask exists at $existing_path but is not managed by Homebrew; leaving it in place"
    else
        info "Installing $cask cask..."
        brew install --cask "$cask"
    fi
}

existing_command_path() {
    command -v "$1" 2>/dev/null || true
}

npm_global_install() {
    local package="$1"

    if npm list -g "$package" >/dev/null 2>&1; then
        ok "$package already installed globally"
    else
        info "Installing global npm package $package..."
        npm install -g "$package"
    fi
}

backup_and_link() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        local current_target
        current_target="$(readlink "$dest")"
        if [ "$current_target" = "$src" ]; then
            ok "$dest already linked"
            return 0
        fi
        rm "$dest"
    elif [ -f "$dest" ] || [ -d "$dest" ]; then
        local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Backing up existing $dest to $backup"
        mv "$dest" "$backup"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    ok "Linked $dest -> $src"
}

ensure_shell_line() {
    local file="$1"
    local pattern="$2"
    local line="$3"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if grep -Fq "$pattern" "$file"; then
        ok "$pattern already present in $file"
    else
        printf "%s\n" "$line" >> "$file"
        ok "Added $pattern to $file"
    fi
}

ensure_shell_line_last() {
    local file="$1"
    local pattern="$2"
    local line="$3"
    local tmp

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if grep -Fq "$pattern" "$file"; then
        tmp="$(mktemp)"
        grep -Fv "$pattern" "$file" > "$tmp" || true
        cat "$tmp" > "$file"
        rm -f "$tmp"
    fi

    printf "%s\n" "$line" >> "$file"
    ok "Ensured $pattern is last in $file"
}

configure_zshrc() {
    local zshrc="$HOME/.zshrc"
    local brew_bin
    brew_bin="$(command -v brew)"

    info "Configuring zsh..."
    ensure_shell_line "$zshrc" "brew shellenv" "eval \"\$($brew_bin shellenv zsh)\""
    ensure_shell_line "$zshrc" '.local/bin' 'export PATH="$HOME/.local/bin:$PATH"'

    if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
        ensure_shell_line "$zshrc" "zsh-completions" 'fpath=("$(brew --prefix)/share/zsh-completions" $fpath)'
        ensure_shell_line "$zshrc" "compinit" 'autoload -Uz compinit && compinit'
        ensure_shell_line "$zshrc" "zsh-autosuggestions.zsh" 'source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"'
    fi

    if [ "$INSTALL_FZF_LINE_ADDED" = true ]; then
        ensure_shell_line "$zshrc" "fzf/shell/key-bindings.zsh" '[ -f "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ] && source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"'
        ensure_shell_line "$zshrc" "fzf/shell/completion.zsh" '[ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ] && source "$(brew --prefix)/opt/fzf/shell/completion.zsh"'
    fi

    if [ "$INSTALL_STARSHIP" = true ]; then
        ensure_shell_line "$zshrc" "starship init zsh" 'eval "$(starship init zsh)"'
    fi

    if [ "$INSTALL_CLI_TOOLS" = true ]; then
        ensure_shell_line "$zshrc" "zoxide init zsh" 'eval "$(zoxide init zsh)"'
        ensure_shell_line "$zshrc" "direnv hook zsh" 'eval "$(direnv hook zsh)"'
    fi

    if [ "$INSTALL_UV" = true ]; then
        ensure_shell_line "$zshrc" "uv generate-shell-completion zsh" 'command -v uv >/dev/null 2>&1 && eval "$(uv generate-shell-completion zsh)"'
    fi

    if [ "$INSTALL_NODE" = true ]; then
        ensure_shell_line "$zshrc" "NVM_DIR" 'export NVM_DIR="$HOME/.nvm"'
        ensure_shell_line "$zshrc" "nvm.sh" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
        ensure_shell_line "$zshrc" "bash_completion" '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'
    fi

    if [ -f "$HOME/.config/workstation/work.zsh" ]; then
        ensure_shell_line "$zshrc" "work.zsh" 'source "$HOME/.config/workstation/work.zsh"'
    fi

    if [ -f "$HOME/.config/workstation/aws.zsh" ]; then
        ensure_shell_line "$zshrc" "aws.zsh" 'source "$HOME/.config/workstation/aws.zsh"'
    fi

    if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
        ensure_shell_line_last "$zshrc" "zsh-syntax-highlighting.zsh" 'source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"'
    fi
}

configure_git() {
    if ! command -v git >/dev/null 2>&1; then
        warn "git not found; skipping git config"
        return 0
    fi

    info "Configuring git..."
    git config --global init.defaultBranch main

    if command -v delta >/dev/null 2>&1; then
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.side-by-side true
        ok "Configured git-delta"
    else
        warn "delta not found; skipping delta git config"
    fi
}

# ----------------------------------------------------------------------------
# HOMEBREW
# ----------------------------------------------------------------------------
if [ "$INSTALL_HOMEBREW" = true ]; then
    info "Checking Homebrew..."
    ensure_homebrew_on_path

    if ! command -v brew >/dev/null 2>&1; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        ensure_homebrew_on_path
    else
        ok "Homebrew already installed"
    fi

    brew update
fi

ensure_homebrew_on_path
if ! command -v brew >/dev/null 2>&1; then
    err "Homebrew is required for this setup. Enable INSTALL_HOMEBREW or install Homebrew first."
    exit 1
fi

# ----------------------------------------------------------------------------
# TERMINAL, SHELL, PROMPT
# ----------------------------------------------------------------------------
if [ "$INSTALL_GHOSTTY" = true ]; then
    info "Setting up Ghostty..."
    brew_cask_install ghostty "/Applications/Ghostty.app"
fi

if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
    info "Installing zsh plugins..."
    brew_install zsh-autosuggestions
    brew_install zsh-syntax-highlighting
    brew_install zsh-completions
fi

if [ "$INSTALL_STARSHIP" = true ]; then
    info "Setting up Starship..."
    brew_install starship
fi

# ----------------------------------------------------------------------------
# CLI TOOLS
# ----------------------------------------------------------------------------
if [ "$INSTALL_CLI_TOOLS" = true ]; then
    info "Installing CLI tools..."
    brew_install fzf
    brew_install ripgrep
    brew_install bat
    brew_install eza
    brew_install fd
    brew_install jq
    brew_install direnv
    brew_install httpie
    brew_install lazygit
    brew_install tlrc
    brew_install zoxide
    brew_install git-delta
    INSTALL_FZF_LINE_ADDED=true
fi

# ----------------------------------------------------------------------------
# PYTHON - uv handles Python installs, venvs, and global tools
# ----------------------------------------------------------------------------
if [ "$INSTALL_UV" = true ]; then
    info "Setting up Python toolchain with uv..."
    brew_install uv
    uv python install "$PYTHON_VERSION"

    for tool in ruff black ipython; do
        if uv tool list 2>/dev/null | grep -Eq "^${tool} "; then
            ok "$tool already installed by uv"
        else
            info "Installing $tool with uv..."
            uv tool install "$tool"
        fi
    done
fi

# ----------------------------------------------------------------------------
# NODE - nvm plus global packages used by the editor/workflow
# ----------------------------------------------------------------------------
if [ "$INSTALL_NODE" = true ]; then
    info "Setting up Node.js with nvm..."

    if [ ! -d "$HOME/.nvm" ]; then
        curl -fsSL -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    else
        ok "nvm already installed"
    fi

    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    if command -v nvm >/dev/null 2>&1; then
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
        npm_global_install pyright
        npm_global_install prettier
        npm_global_install serverless
    else
        warn "nvm not available in this shell. Restart and run: nvm install --lts"
    fi
fi

# ----------------------------------------------------------------------------
# NEOVIM
# ----------------------------------------------------------------------------
if [ "$INSTALL_NEOVIM" = true ]; then
    info "Setting up Neovim..."
    brew_install neovim
    brew_install luarocks
    brew_install lua-language-server
    brew_install stylua
fi

# ----------------------------------------------------------------------------
# TMUX
# ----------------------------------------------------------------------------
if [ "$INSTALL_TMUX" = true ]; then
    info "Setting up tmux..."
    brew_install tmux

    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    else
        ok "TPM already installed"
    fi
fi

# ----------------------------------------------------------------------------
# AWS, DATABASE, GIT, FONT
# ----------------------------------------------------------------------------
if [ "$INSTALL_AWS" = true ]; then
    info "Setting up AWS tools..."
    brew_install awscli
    brew_cask_install aws-vault-binary "$(existing_command_path aws-vault)"
    brew_cask_install session-manager-plugin "$(existing_command_path session-manager-plugin)"
fi

if [ "$INSTALL_DB" = true ]; then
    info "Setting up database tools..."
    brew_install mycli
fi

if [ "$INSTALL_GIT_TOOLS" = true ]; then
    info "Setting up GitHub tooling..."
    brew_install gh
fi

if [ "$INSTALL_FONT" = true ]; then
    info "Installing JetBrains Mono Nerd Font..."
    brew_cask_install font-jetbrains-mono-nerd-font "$HOME/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"
fi

# ----------------------------------------------------------------------------
# DOTFILES
# ----------------------------------------------------------------------------
if [ "$LINK_DOTFILES" = true ]; then
    info "Linking dotfiles..."

    [ -f "$DOTFILES_DIR/starship.toml" ] && backup_and_link "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
    [ -f "$DOTFILES_DIR/ghostty-config" ] && backup_and_link "$DOTFILES_DIR/ghostty-config" "$HOME/.config/ghostty/config"
    [ -f "$DOTFILES_DIR/tmux.conf" ] && backup_and_link "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
    [ -f "$DOTFILES_DIR/init.lua" ] && backup_and_link "$DOTFILES_DIR/init.lua" "$HOME/.config/nvim/init.lua"
    [ -f "$DOTFILES_DIR/work.zsh" ] && backup_and_link "$DOTFILES_DIR/work.zsh" "$HOME/.config/workstation/work.zsh"
    [ -f "$DOTFILES_DIR/aws.zsh" ] && backup_and_link "$DOTFILES_DIR/aws.zsh" "$HOME/.config/workstation/aws.zsh"
fi

if [ "$CONFIGURE_SHELL" = true ]; then
    configure_zshrc
fi

if [ "$CONFIGURE_GIT" = true ]; then
    configure_git
fi

echo ""
echo "============================================================="
info "Setup complete"
echo "============================================================="
echo ""
warn "Post-install steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. In tmux: press Ctrl+a, then I to install TPM plugins"
echo "  3. Open Neovim; lazy.nvim will install plugins on first launch"
echo "  4. Configure AWS credentials if needed: aws-vault add <profile-name>"
echo ""
