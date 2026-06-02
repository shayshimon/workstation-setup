# 🛠️ Workstation Setup

Configurable, idempotent setup script for a macOS dev machine.

## What's Included

| Component | Config File |
|-----------|-------------|
| [Ghostty](https://ghostty.org) terminal | `dotfiles/ghostty-config` |
| Neovim (lazy.nvim + LSP + Telescope) | `dotfiles/init.lua` |
| tmux (vim keys, mouse, TPM) | `dotfiles/tmux.conf` |
| Starship prompt | `dotfiles/starship.toml` |
| `work()` dev launcher | `dotfiles/work.zsh` |

### CLI Tools
fzf, ripgrep, bat, eza, fd, jq, direnv, httpie, lazygit, zoxide, git-delta, tldr

### Dev Toolchain
- **Python:** pyenv, pyenv-virtualenv, pipx, ruff, black
- **Node:** nvm, serverless
- **AWS:** aws-cli, aws-vault, ssm-session-manager-plugin
- **DB:** mycli

## Quick Start

```bash
git clone https://github.com/YOUR_USER/workstation-setup.git
cd workstation-setup
bash setup-workstation.sh
```

## Configuration

Toggle features at the top of `setup-workstation.sh`:

```bash
INSTALL_NEOVIM=true
INSTALL_TMUX=true
INSTALL_STARSHIP=true
INSTALL_GHOSTTY=true
INSTALL_CLI_TOOLS=true
INSTALL_PYTHON=true
INSTALL_NODE=true
INSTALL_AWS=true
# ...
```

## `work` Command

The `work()` function creates a 4-pane tmux layout for any repo:

```
┌──────────┬─────────────────┐
│  codex   │                 │
├──────────┤     nvim        │
│  claude  │                 │
├──────────┤                 │
│ terminal │                 │
└──────────┴─────────────────┘
```

Usage:
```bash
cd ~/projects/my-repo
work
```

Add to `.zshrc`:
```bash
source ~/path/to/dotfiles/work.zsh
```

## Theme

Catppuccin Mocha everywhere (Ghostty, Neovim, tmux status bar).

## Post-Install

1. Restart terminal or `source ~/.zshrc`
2. In tmux: `Ctrl+a, I` to install TPM plugins
3. Open Neovim — lazy.nvim auto-installs on first launch
4. `pyenv install 3.12 && pyenv global 3.12`

## License

MIT
