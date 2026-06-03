# AWS profile switcher.
#
# A plain AWS_PROFILE switcher: it exports the profile (and its region) into
# your CURRENT shell, so every command and deploy script you launch afterwards
# inherits the credentials automatically. Keys live in ~/.aws/credentials and
# the region is read from ~/.aws/config.
#
#   asp <profile>   Switch to <profile>: export AWS_PROFILE plus its region.
#   asp             No argument -> clear AWS_PROFILE and region (back to none).
#   asp-list        List configured profiles.
#
# Starship's [aws] module reads $AWS_PROFILE / $AWS_REGION, so the prompt
# shows the active profile and region.

# _asp_profiles - Emit one profile name per line, parsed from ~/.aws/config.
_asp_profiles() {
    [ -r "$HOME/.aws/config" ] || return 0
    sed -n 's/^\[profile \(.*\)\]$/\1/p; s/^\[\(default\)\]$/\1/p' "$HOME/.aws/config"
}

asp-list() { _asp_profiles }

# _asp_clear_session - Drop any aws-vault / explicit-key session vars. Leftovers
# from an old aws-vault subshell (AWS_VAULT, AWS_SESSION_TOKEN, hard-coded keys)
# would otherwise shadow AWS_PROFILE for the CLI/SDK, and Starship reads
# AWS_VAULT ahead of AWS_PROFILE, so the prompt would show the stale profile.
_asp_clear_session() {
    unset AWS_VAULT AWS_SSO_PROFILE \
          AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY \
          AWS_SESSION_TOKEN AWS_SECURITY_TOKEN \
          AWS_CREDENTIAL_EXPIRATION AWS_SESSION_EXPIRATION
}

# _asp_region <profile> - Emit the region configured for <profile> in
# ~/.aws/config, or nothing if none is set.
_asp_region() {
    local profile="$1" section
    [ -r "$HOME/.aws/config" ] || return 0
    if [ "$profile" = default ]; then
        section="[default]"
    else
        section="[profile $profile]"
    fi
    awk -v s="$section" '
        $0==s {f=1; next}
        /^\[/  {f=0}
        f && /^[[:space:]]*region[[:space:]]*=/ { sub(/.*=[[:space:]]*/, ""); print; exit }
    ' "$HOME/.aws/config"
}

asp() {
    local profile="$1"

    # Always start from a clean slate so AWS_PROFILE is authoritative.
    _asp_clear_session

    # No argument -> clear the active profile and region.
    if [ -z "$profile" ]; then
        unset AWS_PROFILE AWS_REGION AWS_DEFAULT_REGION
        echo "Cleared AWS profile and region." >&2
        return 0
    fi

    # Guard against typos: the profile must exist in ~/.aws/config.
    if ! _asp_profiles | grep -Fqx -- "$profile"; then
        echo "Unknown profile '$profile'. Configured profiles:" >&2
        _asp_profiles >&2
        return 1
    fi

    export AWS_PROFILE="$profile"

    local region; region="$(_asp_region "$profile")"
    if [ -n "$region" ]; then
        export AWS_REGION="$region" AWS_DEFAULT_REGION="$region"
        echo "AWS profile -> $profile (region $region)" >&2
    else
        unset AWS_REGION AWS_DEFAULT_REGION
        echo "AWS profile -> $profile (no region configured)" >&2
    fi
}

# Tab-complete profile names for asp (compdef is defined by compinit).
if (( $+functions[compdef] )); then
    _asp_complete() {
        local -a profiles
        profiles=(${(f)"$(_asp_profiles)"})
        compadd -- $profiles
    }
    compdef _asp_complete asp
fi
