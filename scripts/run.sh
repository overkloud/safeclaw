#!/bin/bash
# Start/reuse container, sync credentials, enter interactively

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_NAME="safeclaw"

# Check if image exists
if ! docker images -q safeclaw | grep -q .; then
    echo "Error: Image 'safeclaw' not found. Run ./scripts/build.sh first."
    exit 1
fi

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # Container exists - check if running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Reusing running container: $CONTAINER_NAME"
    else
        echo "Starting existing container: $CONTAINER_NAME"
        docker start "$CONTAINER_NAME" > /dev/null
    fi
else
    # Create new container
    echo "Creating container: $CONTAINER_NAME"
    docker run -d --ipc=host --name "$CONTAINER_NAME" safeclaw sleep infinity > /dev/null
fi

# Sync config and secrets
"$SCRIPT_DIR/sync-config-and-secrets.sh" "$CONTAINER_NAME"

# Check for Slack token, offer setup if missing
HOST_SECRETS="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw/.secrets"
if [ ! -f "$HOST_SECRETS/slack_bot_token" ] && [ ! -f "$HOST_SECRETS/slack_user_token" ]; then
    echo ""
    echo "=== Slack Setup ==="
    echo ""
    echo "No Slack token found. Want to set up Slack integration?"
    echo "(This script runs locally and won't send your token to AI)"
    echo ""
    read -p "Set up Slack? [y/N]: " setup_slack

    if [[ "$setup_slack" =~ ^[Yy]$ ]]; then
        echo ""
        echo "=== Create Slack App ==="
        echo "1. Go to https://api.slack.com/apps"
        echo "2. Click 'Create New App' > 'From scratch'"
        echo "3. Name it (e.g., 'SafeClaw') and select your workspace"
        echo "4. Go to 'OAuth & Permissions'"
        echo ""
        echo "Which token type?"
        echo "  [B] Bot Token  - can only read channels the bot is added to"
        echo "  [U] User Token - can read all channels you're in"
        echo ""
        read -p "Choose [B/u]: " token_choice
        echo ""

        if [[ "$token_choice" =~ ^[Uu]$ ]]; then
            scope_section="User Token Scopes"
            token_prefix="xoxp-"
            token_file="slack_user_token"
        else
            scope_section="Bot Token Scopes"
            token_prefix="xoxb-"
            token_file="slack_bot_token"
        fi

        echo "Add these read-only scopes to '$scope_section':"
        echo "   - channels:read, channels:history (public channels)"
        echo "   - groups:read, groups:history (private channels)"
        echo "   - users:read (user profiles)"
        echo "   - search:read (search messages)"
        echo "   - (optional) im:read, im:history (DMs)"
        echo "   - (optional) mpim:read, mpim:history (group DMs)"
        echo ""
        echo "5. Left sidebar > 'Install App' > 'Install to Workspace'"
        echo "6. Copy the token (starts with $token_prefix)"
        echo ""
        echo "Token stored at: ~/.config/safeclaw/.secrets/$token_file"
        read -p "Paste token: " slack_token

        if [ -z "$slack_token" ]; then
            echo "No token provided, skipping Slack setup."
        else
            mkdir -p "$HOST_SECRETS"
            echo "$slack_token" > "$HOST_SECRETS/$token_file"
            echo "Saved! Syncing to container..."
            "$SCRIPT_DIR/sync-config-and-secrets.sh" "$CONTAINER_NAME"
        fi
    fi
    echo ""
fi

# Run container setup (idempotent - skips if already done)
docker exec "$CONTAINER_NAME" bash -c "curl -sL https://raw.githubusercontent.com/ykdojo/claude-code-tips/main/scripts/container-setup.sh | bash"

# Copy tools and CLAUDE.md to container
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
docker cp "$PROJECT_DIR/tools" "$CONTAINER_NAME:/home/sclaw/tools"
docker cp "$PROJECT_DIR/setup/CLAUDE.md" "$CONTAINER_NAME:/home/sclaw/.claude/CLAUDE.md"
docker exec -u root "$CONTAINER_NAME" chown -R sclaw:sclaw /home/sclaw/tools /home/sclaw/.claude/CLAUDE.md

# Attach interactively
echo "Entering container..."
docker exec -it "$CONTAINER_NAME" /bin/bash
