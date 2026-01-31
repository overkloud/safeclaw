#!/bin/bash
# Build the safeclaw image

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building image..."
docker build -t safeclaw "$PROJECT_DIR"
