# work() - Launch a 4-pane tmux dev environment for the current repo.
#
# Layout:
#   left top     codex
#   left middle  claude
#   left bottom  terminal
#   right        nvim
#
# Usage:
#   cd /path/to/project && work

# _work_pane_ready - Block until a freshly spawned pane's shell reaches a prompt.
#
# Defeats the race where send-keys fires before the interactive shell has
# finished sourcing its rc files; on a slow startup the first keystrokes are
# silently dropped (e.g. "cd " vanishes, leaving the bare path to be executed).
# Polls capture-pane for a prompt indicator, giving up after ~5s.
_work_pane_ready() {
    local pane="$1" i=0 last
    while [ "$i" -lt 100 ]; do
        last="$(tmux capture-pane -p -t "$pane" 2>/dev/null | grep -v '^[[:space:]]*$' | tail -n 1)"
        case "$last" in
            *❯*|*'$ '*|*'% '*|*'# '*|*'> '*) return 0 ;;
        esac
        sleep 0.05
        i=$((i + 1))
    done
}

work() {
    local dir project_name session_name
    dir="$(pwd)"
    project_name="$(basename "$dir")"
    session_name="dev-session"

    if ! command -v tmux >/dev/null 2>&1; then
        echo "tmux is not installed."
        return 1
    fi

    if [ "${LINES:-999}" -lt 20 ] || [ "${COLUMNS:-999}" -lt 80 ]; then
        echo "Terminal may be too small for the 4-pane layout."
    fi

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -n "init" -c "$dir"
        tmux set-option -t "$session_name" status-position top
    fi

    if tmux list-windows -t "$session_name" -F "#W" | grep -Fqx "$project_name"; then
        echo "Project '$project_name' is already running. Switching..."

        if [ -z "${TMUX:-}" ]; then
            tmux select-window -t "$session_name:$project_name"
            tmux attach-session -t "$session_name"
        else
            tmux select-window -t "$session_name:$project_name"
        fi
        return 0
    fi

    echo "Building tmux workspace for: $project_name"

    local top_pane right_pane middle_pane bottom_pane win_id
    top_pane="$(tmux new-window -t "$session_name" -P -F "#{pane_id}" -n "$project_name" -c "$dir")"
    win_id="$(tmux display-message -p -t "$top_pane" "#{window_id}")"

    right_pane="$(tmux split-window -t "$top_pane" -h -p 65 -c "$dir" -P -F "#{pane_id}")"
    middle_pane="$(tmux split-window -t "$top_pane" -v -p 66 -c "$dir" -P -F "#{pane_id}")"
    bottom_pane="$(tmux split-window -t "$middle_pane" -v -p 50 -c "$dir" -P -F "#{pane_id}")"

    # Panes are already created in "$dir" via -c above, so no cd is needed.
    # Wait for each shell to reach a prompt before sending, or the leading
    # characters of the command get dropped during shell startup.
    _work_pane_ready "$top_pane"
    tmux send-keys -t "$top_pane" "if command -v codex >/dev/null 2>&1; then codex; else echo 'codex is not installed'; fi" C-m

    _work_pane_ready "$middle_pane"
    tmux send-keys -t "$middle_pane" "if command -v claude >/dev/null 2>&1; then claude; else echo 'claude is not installed'; fi" C-m

    _work_pane_ready "$bottom_pane"
    tmux send-keys -t "$bottom_pane" "clear" C-m

    _work_pane_ready "$right_pane"
    tmux send-keys -t "$right_pane" "if command -v nvim >/dev/null 2>&1; then nvim .; else echo 'nvim is not installed'; fi" C-m

    tmux select-window -t "$win_id"
    tmux select-pane -t "$right_pane"
    tmux set-option -t "$session_name" status-position top

    [ -z "${TMUX:-}" ] && tmux attach-session -t "$session_name"
}
