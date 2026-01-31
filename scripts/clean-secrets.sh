#!/bin/bash
# Remove secrets from both host and container

CONTAINER_NAME="${1:-safeclaw}"
HOST_SECRETS="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw/.secrets"
CONTAINER_SECRETS="/home/sclaw/.secrets"

echo "Secrets to delete:"
echo ""
echo "Host ($HOST_SECRETS):"
if [ -d "$HOST_SECRETS" ]; then
    ls -1 "$HOST_SECRETS" 2>/dev/null | sed 's/^/  /' || echo "  (empty)"
else
    echo "  (none)"
fi
echo ""
echo "Container ($CONTAINER_SECRETS):"
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker exec "$CONTAINER_NAME" ls -1 "$CONTAINER_SECRETS" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
else
    echo "  (container not running)"
fi
echo ""
read -p "Delete these? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Clean host
    if [ -d "$HOST_SECRETS" ]; then
        rm -rf "$HOST_SECRETS"
        echo "Removed host secrets"
    fi

    # Clean container
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker exec -u root "$CONTAINER_NAME" rm -rf "$CONTAINER_SECRETS" 2>/dev/null
        echo "Removed container secrets"
    fi

    echo "Done!"
else
    echo "Cancelled"
fi
