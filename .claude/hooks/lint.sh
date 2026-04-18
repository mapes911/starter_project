#!/usr/bin/env bash
# PostToolUse hook: run ESLint on files after Edit or Write.
#
# Receives JSON on stdin with structure:
#   { "tool_name": "Edit", "tool_input": { "file_path": "..." }, ... }
#
# Runs eslint --fix on the modified file if it's a supported type
# and eslint is available in the project.

set -euo pipefail

# Read the hook payload from stdin
payload=$(cat)

# Extract the file path from the tool input
file_path=$(echo "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# No file path — nothing to do
if [ -z "$file_path" ]; then
  exit 0
fi

# Only lint supported file types
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx)
    ;;
  *)
    exit 0
    ;;
esac

# File must exist
if [ ! -f "$file_path" ]; then
  exit 0
fi

# Find the nearest package.json to determine the project root
dir=$(dirname "$file_path")
project_root=""
while [ "$dir" != "/" ]; do
  if [ -f "$dir/package.json" ]; then
    project_root="$dir"
    break
  fi
  dir=$(dirname "$dir")
done

# No package.json found — skip silently
if [ -z "$project_root" ]; then
  exit 0
fi

# Check if eslint is available in this project
if [ ! -x "$project_root/node_modules/.bin/eslint" ]; then
  exit 0
fi

# Run eslint --fix on the file
# Show errors to Claude so it can fix them
if ! "$project_root/node_modules/.bin/eslint" --fix "$file_path" 2>&1; then
  echo "ESLint found issues in $file_path. Please fix them." >&2
  exit 2
fi

exit 0
