# Tool Reference

Quick reference for all CLI tools in this setup.

---

## Shell & Prompt

### Starship
Minimal, fast prompt that shows context (git branch, python venv, node version, aws profile) only when relevant.

Config: `~/.config/starship.toml`

### direnv
Auto-loads environment variables when you `cd` into a directory with a `.envrc` file.

```bash
# Create .envrc in a project
echo 'export AWS_PROFILE=prod' > .envrc
direnv allow    # approve it once
cd out && cd back  # vars auto-load
```

### zoxide
Smart `cd` — remembers directories you visit frequently.

```bash
z projects     # jumps to most-visited dir matching "projects"
z atomic ppc   # fuzzy matches multiple terms
zi             # interactive selection with fzf
```

---

## Navigation & Search

### fzf
Fuzzy finder for everything. Integrates with shell history and file search.

```bash
Ctrl+R         # fuzzy search command history
Ctrl+T         # fuzzy find files
Alt+C          # fuzzy cd into subdirectories
vim $(fzf)     # open a file you search for
```

### ripgrep (`rg`)
Fast recursive text search (replaces grep).

```bash
rg "def train"              # search all files recursively
rg "TODO" --type py         # only Python files
rg "error" -i -l            # case-insensitive, list filenames only
rg "pattern" -C 3           # show 3 lines of context
```

### fd
Fast file finder (replaces find).

```bash
fd "*.py"                   # find all Python files
fd migration --type d       # find directories matching "migration"
fd --extension json --exec jq .  # find + execute
fd -H ".env"                # include hidden files
```

---

## File Viewing & Processing

### bat
`cat` with syntax highlighting and line numbers.

```bash
bat file.py                 # view with colors
bat -l json data.txt        # force language
bat --diff file.py          # show git changes
bat -p file.py              # plain (no line numbers/header)
```

### eza
Modern `ls` with colors and git status.

```bash
eza                         # simple ls
eza -la                     # long format + hidden
eza --tree --level=2        # tree view
eza -l --git                # show git status per file
```

### jq
JSON processor — filter, transform, pretty-print.

```bash
cat data.json | jq '.'              # pretty-print
cat data.json | jq '.items[0].name' # extract field
curl -s api/url | jq '.[] | .id'    # process API response
jq -r '.key' file.json              # raw output (no quotes)
```

### tldr via tlrc
Simplified, example-driven man pages.

```bash
tldr tar        # shows common tar recipes
tldr git rebase # concise git rebase examples
```

---

## Git

### gh (GitHub CLI)
Manage GitHub from terminal — PRs, issues, repos.

```bash
gh pr create                # create PR interactively
gh pr list                  # list open PRs
gh pr checkout 42           # checkout PR #42 locally
gh issue list               # list issues
gh repo view --web          # open repo in browser
gh run list                 # CI run status
```

### lazygit
Terminal UI for git. Launch with `lazygit` in any repo.

```
Space        stage/unstage file
c            commit
p            push
P            pull
?            keybinding help
q            quit
```

### git-delta
Better git diffs — syntax highlighting, side-by-side, line numbers.

The setup script configures delta when `CONFIGURE_GIT=true`. After that, use
`git diff`, `git log -p`, etc. as normal and delta renders them.

Equivalent `~/.gitconfig` settings:
```ini
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    side-by-side = true
```

---

## HTTP & API

### httpie
Clean, human-readable HTTP client (replaces curl for APIs).

```bash
http GET api.example.com/users       # GET request
http POST api.example.com/users name=Shay email=s@a.com  # POST JSON
http -a user:pass GET api.com/data   # basic auth
http --headers GET example.com       # show headers only
http -d GET example.com/file.zip     # download
```

---

## Dev Toolchain

### uv
Manage Python versions, virtual environments, and Python CLI tools.

```bash
uv python install 3.12      # install Python 3.12
uv venv                     # create .venv in the current project
source .venv/bin/activate   # activate the project venv
uv pip install requests     # install a package into the active venv
uv tool list                # list globally installed Python tools
uv tool upgrade --all       # update uv-managed CLI tools
```

### nvm
Manage Node.js versions.

```bash
nvm install --lts           # install latest LTS
nvm use 20                  # switch to v20
nvm alias default 20        # set default
```

---

## AWS

### aws-vault via aws-vault-binary
Securely store and access AWS credentials with MFA.

```bash
aws-vault add production              # store creds
aws-vault exec production -- aws s3 ls  # run command with creds
aws-vault login production            # open console in browser
```

### `asp` — switch profiles (aws-vault wrapper)
Replaces the oh-my-zsh `asp` plugin. Instead of exporting `AWS_PROFILE` with
plaintext keys, it opens a subshell with temporary STS credentials from
aws-vault (keys live in the macOS Keychain). Defined in `dotfiles/aws.zsh`.

```bash
aws-vault add my-profile          # one-time: store keys in the Keychain
asp my-profile                    # subshell with temp creds (exit/Ctrl-D to drop)
asp                               # no arg: pick a profile via fzf
aspx my-profile aws s3 ls         # run one command under a profile, no subshell
asp-list                          # list configured profiles
```

The Starship prompt reads `$AWS_VAULT`, so it shows the active profile while
you are inside an `asp` subshell. Tab-completion works on `asp`/`aspx`.

### ssm-session-manager-plugin
SSH into EC2 instances via AWS SSM (no open ports needed).

```bash
aws ssm start-session --target i-1234567890abcdef0
```

---

## Database

### mycli
MySQL/MariaDB client with autocomplete and syntax highlighting.

```bash
mycli -h hostname -u user -p -D database_name
# Inside:
#   Tab         autocomplete tables/columns
#   Ctrl+D      exit
#   \G          vertical output
```

---

## Tmux

### Key bindings (prefix = Ctrl+a)

```
Ctrl+a |       split vertical
Ctrl+a -       split horizontal
Ctrl+a h/j/k/l   navigate panes (vim keys)
Ctrl+a H/J/K/L   resize panes
Ctrl+a c       new window
Ctrl+a n/p     next/prev window
Ctrl+a r       reload config
Double-click   zoom/unzoom pane
Ctrl+a [       enter copy mode (vim keys, y to yank)
Ctrl+a I       install TPM plugins
```

---

## Neovim

### Key bindings (leader = Space)

```
Space ff       find files (telescope)
Space fg       live grep
Space fb       buffers
Space fr       recent files
Space e        file explorer (neo-tree)
Space /        search in current buffer

gd             go to definition
gr             references
K              hover docs
Space ca       code action
Space rn       rename symbol
Space cf       format file

]h / [h        next/prev git hunk
Space hp       preview hunk
Space hb       blame line

Shift+H/L      prev/next buffer
Space bd       delete buffer
Space w        save
Space q        quit
```
