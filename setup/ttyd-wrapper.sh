#!/bin/bash
# Pass env vars to tmux session

# Attach to existing session, or create new one with claude
if tmux has-session -t main 2>/dev/null; then
    exec tmux attach -t main
else
    # Create session
    tmux -f /dev/null new -d -s main
    tmux set -t main status off
    tmux set -t main mouse on

    # Pass all env vars to the session
    while IFS='=' read -r name value; do
        tmux set-environment -t main "$name" "$value"
    done < <(env)

    # Have the shell load the tmux environment, then start claude
    tmux send-keys -t main 'eval "$(tmux show-environment -s)" && claude --dangerously-skip-permissions' Enter
    exec tmux attach -t main
fi
