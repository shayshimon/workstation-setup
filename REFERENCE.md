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

### tldr
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

Already configured via `.gitconfig`. Just use `git diff`, `git log -p`, etc. as normal — delta renders them.

To enable, add to `~/.gitconfig`:
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

### pyenv
Manage multiple Python versions.

```bash
pyenv install 3.12.3        # install a version
pyenv global 3.12.3         # set default
pyenv local 3.11.9          # set per-project (.python-version)
pyenv versions              # list installed
```

### pyenv-virtualenv
Virtual environments tied to pyenv.

```bash
pyenv virtualenv 3.12.3 myproject    # create venv
pyenv activate myproject             # activate
pyenv deactivate                     # deactivate
pyenv local myproject                # auto-activate in this dir
```

### pipx
Install Python CLI tools in isolated environments.

```bash
pipx install ruff           # install globally without conflicts
pipx install black
pipx list                   # see what's installed
pipx upgrade-all            # update everything
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

### aws-vault
Securely store and access AWS credentials with MFA.

```bash
aws-vault add production              # store creds
aws-vault exec production -- aws s3 ls  # run command with creds
aws-vault login production            # open console in browser
```

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
