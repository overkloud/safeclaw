#!/bin/bash
# Set up Slack integration for SafeClaw

SECRETS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw/.secrets"

echo ""
echo "=== Slack Setup ==="
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
else
    scope_section="Bot Token Scopes"
    token_prefix="xoxb-"
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
read -p "Paste token: " slack_token

if [ -z "$slack_token" ]; then
    echo "No token provided, skipping Slack setup."
else
    mkdir -p "$SECRETS_DIR"
    echo "$slack_token" > "$SECRETS_DIR/SLACK_TOKEN"
    echo ""
    echo "Saved to $SECRETS_DIR/SLACK_TOKEN"
    echo ""
    echo "Restart SafeClaw to use Slack:"
    echo "  ./scripts/run.sh"
fi
