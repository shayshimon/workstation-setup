# AWS profile helpers backed by aws-vault.
#
# Replaces the oh-my-zsh `asp` ("aws switch profile") plugin. The difference:
# the old asp just `export`ed AWS_PROFILE and relied on plaintext keys in
# ~/.aws/credentials. These helpers source temporary, auto-expiring STS
# credentials from aws-vault (keys live in the macOS Keychain), and start a
# subshell rather than mutating your current one.
#
#   asp [profile]            Open a subshell with credentials for <profile>.
#                            No argument -> pick interactively (needs fzf).
#                            Exit the subshell (exit / Ctrl-D) to drop the creds.
#   aspx <profile> <cmd...>  Run a single command under <profile>, then return.
#   asp-list                 List configured profiles.
#
# Starship's [aws] module reads $AWS_VAULT, so the prompt shows the active
# profile while you are inside an asp subshell.

# _asp_profiles - Emit one profile name per line, from aws-vault if available,
# else by parsing ~/.aws/config.
_asp_profiles() {
    if command -v aws-vault >/dev/null 2>&1; then
        aws-vault list --profiles 2>/dev/null
    elif [ -r "$HOME/.aws/config" ]; then
        sed -n 's/^\[profile \(.*\)\]$/\1/p; s/^\[\(default\)\]$/\1/p' "$HOME/.aws/config"
    fi
}

asp-list() { _asp_profiles }

asp() {
    if ! command -v aws-vault >/dev/null 2>&1; then
        echo "aws-vault is not installed (brew install --cask aws-vault-binary)." >&2
        return 1
    fi

    if [ -n "$AWS_VAULT" ]; then
        echo "Already in an aws-vault subshell for '$AWS_VAULT' — exit it first." >&2
        return 1
    fi

    local profile="$1"
    if [ -z "$profile" ]; then
        if command -v fzf >/dev/null 2>&1; then
            profile="$(_asp_profiles | fzf --prompt='aws profile> ' --height=40% --reverse)"
        else
            echo "Available profiles (pass one as an argument):" >&2
            _asp_profiles >&2
            return 0
        fi
    fi
    [ -z "$profile" ] && return 0

    echo "aws-vault subshell for '$profile' — exit or Ctrl-D to drop credentials." >&2
    aws-vault exec "$profile"
}

aspx() {
    if ! command -v aws-vault >/dev/null 2>&1; then
        echo "aws-vault is not installed (brew install --cask aws-vault-binary)." >&2
        return 1
    fi
    local profile="$1"
    shift 2>/dev/null
    if [ -z "$profile" ] || [ "$#" -eq 0 ]; then
        echo "usage: aspx <profile> <command> [args...]" >&2
        return 1
    fi
    aws-vault exec "$profile" -- "$@"
}

# Tab-complete profile names for asp/aspx (compdef is defined by compinit).
if (( $+functions[compdef] )); then
    _asp_complete() {
        local -a profiles
        profiles=(${(f)"$(_asp_profiles)"})
        compadd -- $profiles
    }
    compdef _asp_complete asp aspx
fi
