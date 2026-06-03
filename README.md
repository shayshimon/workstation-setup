# Workstation Setup

Configurable, idempotent setup script for a macOS development machine.

The script is intended for a fresh laptop, but it is safe to re-run. Existing
dotfiles are backed up with timestamped `.bak.YYYYMMDDHHMMSS` suffixes before
repo-managed dotfiles are linked.

## What's Included

| Component | Config File |
|-----------|-------------|
| Ghostty terminal | `dotfiles/ghostty-config` |
| Neovim with lazy.nvim, LSP, Telescope, Treesitter, completion, and formatting | `dotfiles/init.lua` |
| tmux with vim keys, mouse, TPM, resurrect, and continuum | `dotfiles/tmux.conf` |
| Starship prompt | `dotfiles/starship.toml` |
| `work()` tmux dev launcher | `dotfiles/work.zsh` |

## Tooling

Shell and prompt:
- Homebrew
- zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions
- Starship
- zoxide
- direnv
- fzf shell key bindings and completion

CLI tools:
- fzf, ripgrep, bat, eza, fd, jq
- httpie, lazygit, git-delta, tlrc (`tldr` command)

Development toolchain:
- Python: `uv`, Python 3.12, `ruff`, `black`, `ipython`
- Node: `nvm`, latest LTS Node, `pyright`, `prettier`, `serverless`
- Neovim support: `lua-language-server`, `stylua`, `luarocks`
- AWS: `awscli`, `aws-vault-binary` (`aws-vault` command), `session-manager-plugin`
- Database: `mycli`
- GitHub: `gh`

## Quick Start

```bash
git clone https://github.com/YOUR_USER/workstation-setup.git
cd workstation-setup
bash setup-workstation.sh
```

## Configuration

Toggle features at the top of `setup-workstation.sh`:

```bash
INSTALL_HOMEBREW=true
INSTALL_GHOSTTY=true
INSTALL_ZSH_PLUGINS=true
INSTALL_STARSHIP=true
INSTALL_CLI_TOOLS=true
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
```

## `work` Command

The `work()` function creates a 4-pane tmux layout for any repo:

```text
+----------+-----------------+
| codex    |                 |
+----------+     nvim        |
| claude   |                 |
+----------+                 |
| terminal |                 |
+----------+-----------------+
```

Usage:

```bash
cd ~/projects/my-repo
work
```

The installer links `dotfiles/work.zsh` to `~/.config/workstation/work.zsh` and
adds it to `~/.zshrc`.

## AWS Profiles

`dotfiles/aws.zsh` provides a simple `asp` profile switcher. It exports
`AWS_PROFILE` (and the profile's region from `~/.aws/config`) into your current
shell, so every command and deploy script you launch afterwards inherits the
credentials. Keys live in `~/.aws/credentials`.

```bash
asp my-profile     # switch: export AWS_PROFILE + region into this shell
asp                # no arg: clear AWS_PROFILE and region
asp-list           # list configured profiles
```

See [REFERENCE.md](REFERENCE.md#aws) for details.

## Post-Install

1. Restart the terminal or run `source ~/.zshrc`.
2. In tmux, press `Ctrl+a`, then `I` to install TPM plugins.
3. Open Neovim; lazy.nvim installs plugins on first launch.
4. Configure AWS credentials if needed in `~/.aws/credentials` and `~/.aws/config`.

## License

MIT
