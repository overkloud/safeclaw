# SafeClaw

Sandboxed Docker container running Claude Code, accessible via a web terminal.

See [architecture.md](architecture.md) for full design details.

## Testing end to end

After making changes, rebuild and test:

```bash
./scripts/build.sh
./scripts/run.sh
```

This opens http://localhost:7681 in the browser. Verify:
1. Claude Code launches automatically with bypass permissions
2. Confirm it shows the correct model (Opus 4.5) and doesn't ask for login
3. Send a message and confirm it gets a response

If the web terminal is frozen, run `./scripts/restart.sh`.

## Sending commands to the container via tmux

When sending commands to the container's tmux session with `tmux send-keys`, the message may not go through on the first Enter. If `tmux capture-pane` shows the prompt is still empty (the `❯` line has no text after it, or the text is there but hasn't been submitted), send additional Enter keys:

```bash
docker exec safeclaw tmux send-keys -t main Enter
```

Always verify with `tmux capture-pane -t main -p` that the command was actually submitted.
