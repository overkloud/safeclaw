#!/bin/bash
# Sync config and secrets between container and host (newer wins)

CONTAINER_NAME="${1:-safeclaw}"
HOST_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/safeclaw"

# Start container if not running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Starting container: $CONTAINER_NAME"
        docker start "$CONTAINER_NAME" > /dev/null
    else
        echo "Error: Container '$CONTAINER_NAME' doesn't exist. Run ./scripts/run.sh first."
        exit 1
    fi
fi

# Sync entire directory (for config - uses marker file to compare)
sync_dir() {
    local name="$1"
    local host_dir="$2"
    local container_dir="$3"
    local marker="$4"

    local container_has=false
    local host_has=false

    docker exec "$CONTAINER_NAME" test -f "$container_dir/$marker" 2>/dev/null && container_has=true
    [ -f "$host_dir/$marker" ] && host_has=true

    if $container_has && ! $host_has; then
        echo "[$name] Syncing: container -> host"
        mkdir -p "$host_dir"
        docker cp "$CONTAINER_NAME:$container_dir/." "$host_dir/"

    elif $host_has && ! $container_has; then
        echo "[$name] Syncing: host -> container"
        docker exec "$CONTAINER_NAME" mkdir -p "$container_dir"
        docker cp "$host_dir/." "$CONTAINER_NAME:$container_dir/"
        docker exec -u root "$CONTAINER_NAME" chown -R sclaw:sclaw "$container_dir"

    elif $container_has && $host_has; then
        local container_time=$(docker exec "$CONTAINER_NAME" stat -c %Y "$container_dir/$marker" 2>/dev/null)
        local host_time=$(stat -f %m "$host_dir/$marker" 2>/dev/null)

        if [ "$container_time" -gt "$host_time" ]; then
            echo "[$name] Syncing: container -> host (container is newer)"
            rm -rf "$host_dir"
            mkdir -p "$host_dir"
            docker cp "$CONTAINER_NAME:$container_dir/." "$host_dir/"
        elif [ "$host_time" -gt "$container_time" ]; then
            echo "[$name] Syncing: host -> container (host is newer)"
            docker exec -u root "$CONTAINER_NAME" rm -rf "$container_dir"
            docker exec "$CONTAINER_NAME" mkdir -p "$container_dir"
            docker cp "$host_dir/." "$CONTAINER_NAME:$container_dir/"
            docker exec -u root "$CONTAINER_NAME" chown -R sclaw:sclaw "$container_dir"
        else
            echo "[$name] Already in sync"
        fi
    fi
}

# Sync secrets directory (merges files, each file synced independently)
sync_secrets() {
    local host_dir="$HOST_BASE/.secrets"
    local container_dir="/home/sclaw/.secrets"

    mkdir -p "$host_dir"
    docker exec "$CONTAINER_NAME" mkdir -p "$container_dir" 2>/dev/null

    # Get list of files from both sides
    local host_files=$(ls -1 "$host_dir" 2>/dev/null || true)
    local container_files=$(docker exec "$CONTAINER_NAME" ls -1 "$container_dir" 2>/dev/null || true)

    # Combine unique file names
    local all_files=$(echo -e "$host_files\n$container_files" | sort -u | grep -v '^$')

    if [ -z "$all_files" ]; then
        return
    fi

    for file in $all_files; do
        local host_has=false
        local container_has=false

        [ -f "$host_dir/$file" ] && host_has=true
        docker exec "$CONTAINER_NAME" test -f "$container_dir/$file" 2>/dev/null && container_has=true

        if $host_has && ! $container_has; then
            echo "[secrets] $file: host -> container"
            docker cp "$host_dir/$file" "$CONTAINER_NAME:$container_dir/$file"
            docker exec -u root "$CONTAINER_NAME" chown sclaw:sclaw "$container_dir/$file"

        elif $container_has && ! $host_has; then
            echo "[secrets] $file: container -> host"
            docker cp "$CONTAINER_NAME:$container_dir/$file" "$host_dir/$file"

        elif $host_has && $container_has; then
            local container_time=$(docker exec "$CONTAINER_NAME" stat -c %Y "$container_dir/$file" 2>/dev/null)
            local host_time=$(stat -f %m "$host_dir/$file" 2>/dev/null)

            if [ "$container_time" -gt "$host_time" ]; then
                echo "[secrets] $file: container -> host (newer)"
                docker cp "$CONTAINER_NAME:$container_dir/$file" "$host_dir/$file"
            elif [ "$host_time" -gt "$container_time" ]; then
                echo "[secrets] $file: host -> container (newer)"
                docker cp "$host_dir/$file" "$CONTAINER_NAME:$container_dir/$file"
                docker exec -u root "$CONTAINER_NAME" chown sclaw:sclaw "$container_dir/$file"
            fi
        fi
    done
}

# Sync Claude credentials (compare expiresAt, not file timestamps)
sync_credentials() {
    local host_file="$HOST_BASE/.claude/.credentials.json"
    local container_file="/home/sclaw/.claude/.credentials.json"

    local container_has=false
    local host_has=false

    docker exec "$CONTAINER_NAME" test -f "$container_file" 2>/dev/null && container_has=true
    [ -f "$host_file" ] && host_has=true

    if $container_has && ! $host_has; then
        echo "[credentials] Syncing: container -> host"
        mkdir -p "$HOST_BASE/.claude"
        docker cp "$CONTAINER_NAME:$container_file" "$host_file"

    elif $host_has && ! $container_has; then
        echo "[credentials] Syncing: host -> container"
        docker exec "$CONTAINER_NAME" mkdir -p /home/sclaw/.claude
        docker cp "$host_file" "$CONTAINER_NAME:$container_file"
        docker exec -u root "$CONTAINER_NAME" chown sclaw:sclaw "$container_file"

    elif $container_has && $host_has; then
        local container_expiry=$(docker exec "$CONTAINER_NAME" jq -r '.claudeAiOauth.expiresAt // 0' "$container_file" 2>/dev/null)
        local host_expiry=$(jq -r '.claudeAiOauth.expiresAt // 0' "$host_file" 2>/dev/null)

        if [ "$container_expiry" -gt "$host_expiry" ]; then
            echo "[credentials] Syncing: container -> host (container token expires later)"
            docker cp "$CONTAINER_NAME:$container_file" "$host_file"
        elif [ "$host_expiry" -gt "$container_expiry" ]; then
            echo "[credentials] Syncing: host -> container (host token expires later)"
            docker cp "$host_file" "$CONTAINER_NAME:$container_file"
            docker exec -u root "$CONTAINER_NAME" chown sclaw:sclaw "$container_file"
        else
            echo "[credentials] Already in sync"
        fi
    fi
}

# Sync Claude credentials first (uses expiresAt comparison)
sync_credentials

# Sync rest of Claude config (uses file timestamp comparison)
sync_dir "config" "$HOST_BASE/.claude" "/home/sclaw/.claude" ".credentials.json"

# Sync GitHub CLI config (whole directory)
sync_dir "gh" "$HOST_BASE/.gh" "/home/sclaw/.config/gh" "hosts.yml"

# Sync secrets (merge files)
sync_secrets
