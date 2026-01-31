# SafeClaw

Safety-first personal AI assistant. All execution happens in Docker - no host access.

## Quick start

```bash
# Build the image (once, or after Dockerfile changes)
./scripts/build.sh

# Run and enter interactively
./scripts/run.sh
```

## What's included

- Ubuntu 24.04
- Node.js 24 (LTS)
- Playwright with Chromium
- Claude Code 2.1.19

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/build.sh` | Build the Docker image |
| `scripts/run.sh` | Start/reuse container and enter interactively |
| `scripts/sync-config-and-secrets.sh` | Sync config and secrets between container and host |
| `scripts/clean-secrets.sh` | Remove all secrets from host and container |

## Auto-setup

On `run.sh`, the container automatically configures:

- **[DX plugin](https://github.com/ykdojo/claude-code-tips#tip-44-install-the-dx-plugin)** - slash commands (`/gha`, `/clone`, `/handoff`) and skills
- **Status line** - shows model, git branch, tokens at bottom of screen
- **Aliases** - `c`=claude, `cs`=claude --dangerously-skip-permissions
- **Fork shortcut** - `--fs` expands to `--fork-session`

## Sync

Your Claude login and secrets are preserved on the host, so you only need to set them up once - even if you rebuild or delete the container.

`sync-config-and-secrets.sh` syncs:

| What | Host | Container | Behavior |
|------|------|-----------|----------|
| Config | `~/.config/safeclaw/.claude/` | `/home/sclaw/.claude/` | Whole directory, newer wins |
| Secrets | `~/.config/safeclaw/.secrets/` | `/home/sclaw/.secrets/` | Per-file merge, each file synced independently |

**First time setup:**
1. Run `./scripts/run.sh` and log in to Claude Code
2. Run `./scripts/sync-config-and-secrets.sh` to save to host

After that, `run.sh` syncs automatically on each start.
