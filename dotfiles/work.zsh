# work() — Launch a 4-pane tmux dev environment for the current repo
# Layout: Left side (35%) split into 3 panes (codex, claude, terminal)
#         Right side (65%) is nvim
#
# Usage: cd /path/to/project && work
#
# Source this file from .zshrc:
#   source ~/dotfiles/work.zsh   (or wherever you keep it)

work() {
    local dir=$(pwd)
    local project_name=$(basename "$dir")
    local session_name="dev-session"

    # 1. Ensure the session exists
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -n "init"
        tmux set-option -t "$session_name" status-position top
    fi

    # 2. Check if project window already exists (exact match)
    if tmux list-windows -t "$session_name" -F "#W" | grep -qx "$project_name"; then
        echo "✨ Project '$project_name' is already running. Switching..."

        if [ -z "$TMUX" ]; then
            tmux attach-session -t "$session_name" \; select-window -t "$project_name"
        else
            tmux select-window -t "$session_name:$project_name"
        fi
        return 0
    fi

    # 3. Safety check
    if [ "$LINES" -lt 20 ] || [ "$COLUMNS" -lt 80 ]; then
        echo "⚠️  Terminal might be too small for the 4-pane layout. Please enlarge."
    fi

    echo "🚀 Building fresh dashboard for: $project_name"

    # 4. Create window and split into 4 panes
    local win_id=$(tmux new-window -t "$session_name" -P -F "#{window_id}" -n "$project_name" -c "$dir")

    # Right side (65%) — nvim
    tmux split-window -t "$win_id" -h -p 65 -c "$dir"

    # Left side splits: top=codex, mid=claude, bottom=terminal
    tmux split-window -t "$win_id.0" -v -p 66 -c "$dir"
    tmux split-window -t "$win_id.1" -v -p 50 -c "$dir"

    # 5. Launch tools in each pane
    tmux send-keys -t "$win_id.0" "cd '$dir' && codex" C-m
    tmux send-keys -t "$win_id.1" "cd '$dir' && claude" C-m
    tmux send-keys -t "$win_id.2" "cd '$dir' && clear" C-m
    tmux send-keys -t "$win_id.3" "cd '$dir' && nvim ." C-m

    # 6. Focus on nvim pane
    tmux select-window -t "$win_id"
    tmux select-pane -t "$win_id.3"
    tmux set-option -g status-position top

    # Attach if not already inside tmux
    [ -z "$TMUX" ] && tmux attach-session -t "$session_name"
}
