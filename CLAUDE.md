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
1. tmux session starts
2. Run `cs` to launch Claude Code with bypass permissions
3. Accept the bypass permissions prompt
4. Confirm it shows the correct model (Opus 4.5) and doesn't ask for login
5. Send a message and confirm it gets a response (you may need to press Enter a few times for it to go through)

If the web terminal is frozen, run `./scripts/restart.sh`.
