# SafeClaw

Safety-first personal AI assistant. All execution happens in Docker - no host access.

## Core idea

OpenClaw runs on host by default. This runs everything in a container. Simple.

## Distribution

- `npm install` - easiest way to distribute
- On first run, sets up Docker container automatically
- Prompts user for Anthropic API key / sets up environment

## Docker image

Use official Playwright image: `mcr.microsoft.com/playwright:v1.58.0-noble` (879MB)

Includes:
- Ubuntu 24.04 LTS
- Node.js 24, npm, yarn, git
- All three browser engines (Chromium, Firefox, WebKit)
- Screenshots work out of the box

Run with `--ipc=host` or Chromium crashes.

Install on top:
- Claude Code (pinned to specific version)
- SDKs: Slack, Telegram
- ~~WhatsApp~~ - not feasible (Meta banned general-purpose AI bots Jan 2026, unofficial libs broken)

## Minimum features (weekend scope)

1. **Chat interface** - Telegram or Discord bot
2. **Containerized execution** - All bash/code runs in Docker
3. **Persistent memory** - File-based context that survives restarts
4. **Basic tools** - Web search, file read/write, bash (all inside container)

## Name ideas

- SafeClaw, Sandbox, Citadel, Moat, Padded
