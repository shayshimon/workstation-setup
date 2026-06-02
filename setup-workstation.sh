#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# WORKSTATION SETUP SCRIPT
# ============================================================================
# Configurable, idempotent setup for a macOS dev machine.
# Toggle sections on/off below. Safe to re-run.
# ============================================================================

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — Toggle features on/off
# ──────────────────────────────────────────────────────────────────────────────
INSTALL_HOMEBREW=true
INSTALL_GHOSTTY=true
INSTALL_ZSH_PLUGINS=true
INSTALL_STARSHIP=true
INSTALL_NEOVIM=true
INSTALL_TMUX=true
INSTALL_CLI_TOOLS=true
INSTALL_UV=true
INSTALL_NODE=true
INSTALL_AWS=true
INSTALL_DB=true
INSTALL_GIT_TOOLS=true
INSTALL_FONT=true
LINK_DOTFILES=true

# Where this script and dotfiles live
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────────────────────
info()  { printf "\033[1;34m⟹  %s\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m✓  %s\033[0m\n" "$1"; }
warn()  { printf "\033[1;33m⚠  %s\033[0m\n" "$1"; }
err()   { printf "\033[1;31m✗  %s\033[0m\n" "$1"; }

brew_install() {
    if brew list "$1" &>/dev/null; then
        ok "$1 already installed"
    else
        info "Installing $1..."
        brew install "$1"
    fi
}

brew_cask_install() {
    if brew list --cask "$1" &>/dev/null; then
        ok "$1 (cask) already installed"
    else
        info "Installing $1 (cask)..."
        brew install --cask "$1"
    fi
}

backup_and_link() {
    local src="$1"
    local dest="$2"
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -f "$dest" ] || [ -d "$dest" ]; then
        warn "Backing up existing $dest → ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    ok "Linked $dest → $src"
}

# ──────────────────────────────────────────────────────────────────────────────
# HOMEBREW
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_HOMEBREW" = true ]; then
    info "Checking Homebrew..."
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add to path for Apple Silicon
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        ok "Homebrew already installed"
    fi
    brew update
fi

# ──────────────────────────────────────────────────────────────────────────────
# GHOSTTY
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_GHOSTTY" = true ]; then
    info "Setting up Ghostty..."
    brew_cask_install ghostty
fi

# ──────────────────────────────────────────────────────────────────────────────
# ZSH + OH MY ZSH + PLUGINS
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_ZSH_PLUGINS" = true ]; then
    info "Setting up Zsh + Oh My Zsh..."

    # Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        ok "Oh My Zsh already installed"
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    else
        ok "zsh-autosuggestions already installed"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    else
        ok "zsh-syntax-highlighting already installed"
    fi

    # zsh-completions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
        git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
    else
        ok "zsh-completions already installed"
    fi

    # Remind user to update .zshrc plugins
    echo ""
    warn "Add these to your .zshrc plugins list:"
    echo '  plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions direnv)'
    echo ""
fi

# ──────────────────────────────────────────────────────────────────────────────
# STARSHIP PROMPT
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_STARSHIP" = true ]; then
    info "Setting up Starship..."
    brew_install starship

    # Remind to add to .zshrc
    warn "Add to end of .zshrc:  eval \"\$(starship init zsh)\""
fi

# ──────────────────────────────────────────────────────────────────────────────
# NEOVIM
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_NEOVIM" = true ]; then
    info "Setting up Neovim..."
    brew_install neovim
    brew_install luarocks  # for some plugins

    # LSP servers
    brew_install lua-language-server

    # Python LSP (pyright) via npm later, or:
    if command -v npm &>/dev/null; then
        npm list -g pyright &>/dev/null || npm install -g pyright
    else
        warn "npm not found — install pyright later: npm install -g pyright"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# TMUX
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_TMUX" = true ]; then
    info "Setting up tmux..."
    brew_install tmux

    # TPM (Tmux Plugin Manager)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    else
        ok "TPM already installed"
    fi
    warn "After first tmux launch, press prefix + I to install plugins"
fi

# ──────────────────────────────────────────────────────────────────────────────
# CLI TOOLS
# ──────────────────────────────────────────────────────────────────────────────
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
    brew_install tldr
    brew_install zoxide    # smart cd
    brew_install git-delta # better diffs

    # fzf keybindings
    if [ ! -f "$HOME/.fzf.zsh" ]; then
        "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    fi

    warn "Add to .zshrc:  eval \"\$(zoxide init zsh)\""
    warn "Add to .gitconfig:  [core] pager = delta"
fi

# ──────────────────────────────────────────────────────────────────────────────
# PYTHON (uv — handles versions, venvs, and tool installs)
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_UV" = true ]; then
    info "Setting up Python toolchain (uv)..."

    # Install uv
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    else
        ok "uv already installed"
    fi

    # Install Python
    uv python install 3.12

    # Global CLI tools via uv tool
    for tool in ruff black ipython; do
        if ! uv tool list 2>/dev/null | grep -q "$tool"; then
            uv tool install "$tool"
        else
            ok "$tool (uv tool) already installed"
        fi
    done

    warn "Add to .zshrc:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    echo '  eval "$(uv generate-shell-completion zsh)"'
fi

# ──────────────────────────────────────────────────────────────────────────────
# NODE (nvm + serverless)
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_NODE" = true ]; then
    info "Setting up Node.js (nvm)..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    else
        ok "nvm already installed"
    fi

    # Source nvm for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest LTS
    if command -v nvm &>/dev/null; then
        nvm install --lts
        nvm use --lts

        # Serverless Framework
        npm list -g serverless &>/dev/null || npm install -g serverless
        ok "Serverless Framework installed"
    else
        warn "nvm not available in this session — restart shell and run: nvm install --lts && npm install -g serverless"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# AWS TOOLS
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_AWS" = true ]; then
    info "Setting up AWS tools..."
    brew_install awscli
    brew_cask_install aws-vault
    brew_install session-manager-plugin
fi

# ──────────────────────────────────────────────────────────────────────────────
# DATABASE TOOLS
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_DB" = true ]; then
    info "Setting up database tools..."
    brew_install mycli
fi

# ──────────────────────────────────────────────────────────────────────────────
# GIT TOOLS
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_GIT_TOOLS" = true ]; then
    info "Setting up Git tools..."
    brew_install gh
    # lazygit already in CLI_TOOLS, delta already in CLI_TOOLS
fi

# ──────────────────────────────────────────────────────────────────────────────
# FONT — JetBrains Mono Nerd Font
# ──────────────────────────────────────────────────────────────────────────────
if [ "$INSTALL_FONT" = true ]; then
    info "Installing JetBrains Mono Nerd Font..."
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew_cask_install font-jetbrains-mono-nerd-font
fi

# ──────────────────────────────────────────────────────────────────────────────
# DOTFILE LINKING
# ──────────────────────────────────────────────────────────────────────────────
if [ "$LINK_DOTFILES" = true ]; then
    info "Linking dotfiles..."

    # Starship
    if [ -f "$DOTFILES_DIR/starship.toml" ]; then
        backup_and_link "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
    fi

    # Ghostty
    if [ -f "$DOTFILES_DIR/ghostty-config" ]; then
        mkdir -p "$HOME/.config/ghostty"
        backup_and_link "$DOTFILES_DIR/ghostty-config" "$HOME/.config/ghostty/config"
    fi

    # Tmux
    if [ -f "$DOTFILES_DIR/tmux.conf" ]; then
        backup_and_link "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
    fi

    # Neovim
    if [ -f "$DOTFILES_DIR/init.lua" ]; then
        mkdir -p "$HOME/.config/nvim"
        backup_and_link "$DOTFILES_DIR/init.lua" "$HOME/.config/nvim/init.lua"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# DONE
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Setup complete! 🎉"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
warn "Post-install steps:"
echo "  1. Restart your terminal (or source ~/.zshrc)"
echo "  2. In tmux: press Ctrl+a, then I to install tmux plugins"
echo "  3. Open Neovim — lazy.nvim will auto-install plugins on first launch"
echo "  4. Run: pyenv install 3.12 && pyenv global 3.12"
echo "  5. Configure aws-vault: aws-vault add <profile-name>"
echo ""
