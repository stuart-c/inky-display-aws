#!/bin/bash
set -e

# Get repository URL
REPO_URL=$(git config --get remote.origin.url || echo "https://github.com/stuart-c/inky-display-aws")

# Get repository name (extract from URL or existing folder, falling back to a default)
# Assumes standard github https/ssh format, grabs the last part without .git
REPO_NAME=$(basename -s .git "$REPO_URL")

# Strip .git from the URL if valid
REPO_URL=${REPO_URL%.git}

# Output JSON
jq -n --arg name "$REPO_NAME" --arg url "$REPO_URL" '{"name":$name, "url":$url}'
