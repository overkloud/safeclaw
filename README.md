# SafeClaw

Safety-first personal AI assistant. All execution happens in Docker - no host access.

See [architecture.md](architecture.md) for design details.

## Quick start

```bash
# Build image (once, or after changes)
./scripts/build.sh

# Start container and web terminal
./scripts/run.sh

# To mount a local project (host_path:container_path)
./scripts/run.sh -v ~/myproject:/home/sclaw/myproject
```

On first run, `run.sh` will prompt you to set up authentication tokens. It then starts a web terminal at http://localhost:7681 and opens it in your browser.

## What's included

- Ubuntu 24.04
- Node.js 24 (LTS)
- Claude Code 2.1.19
- GitHub CLI
- Playwright MCP with Chromium
- DX plugin, status line, aliases
- ttyd web terminal + tmux

## Authentication

Tokens are stored in `~/.config/safeclaw/.secrets/` and injected as env vars on each run. The filename becomes the env var name.

| File | How to generate |
|------|-----------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | `claude setup-token` (valid 1 year) |
| `GH_TOKEN` | `gh auth token` or create a PAT at github.com/settings/tokens |

You can add any additional secrets by creating files in the `.secrets/` directory. For example, `SLACK_TOKEN` becomes the `SLACK_TOKEN` env var.

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/build.sh` | Build the Docker image and remove old container |
| `scripts/run.sh` | Start/reuse container, inject auth, start ttyd on port 7681. Use `-v` to mount a volume. |
| `scripts/restart.sh` | Kill and restart the web terminal (ttyd + tmux) |
| `scripts/setup-slack.sh` | Set up Slack integration (optional) |
