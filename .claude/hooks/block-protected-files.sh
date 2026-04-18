#!/usr/bin/env bash
# PreToolUse hook: block edits to protected/sensitive files.
#
# Receives JSON on stdin with structure:
#   { "tool_name": "Edit", "tool_input": { "file_path": "..." }, ... }
#
# Exits with code 2 to block the edit and feed the error back to Claude.

set -euo pipefail

# Read the hook payload and extract the file path via sed.
payload=$(cat)
file=$(echo "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# Fall back to "path" key if file_path wasn't present
if [ -z "$file" ]; then
  file=$(echo "$payload" | sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

# No file — nothing to check
if [ -z "$file" ]; then
  exit 0
fi

protected=(
  ".env*"
  ".git/*"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  "*.pem"
  "*.key"
  "secrets/*"
)

# Strip leading path to check just the basename and relative path segments
basename=$(basename "$file")

for pattern in "${protected[@]}"; do
  # Convert glob-style pattern to regex (* becomes .*)
  regex="^${pattern//\*/.*}$"

  # Check both the full path and the basename against the pattern
  if echo "$file" | grep -qiE "$regex" || echo "$basename" | grep -qiE "$regex"; then
    echo "Blocked: '$file' is protected. Explain why this edit is necessary." >&2
    exit 2
  fi
done

exit 0
