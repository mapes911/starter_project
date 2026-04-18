#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Edit or Write.
#
# Receives JSON on stdin with structure:
#   { "tool_name": "Edit", "tool_input": { "file_path": "..." }, ... }
#
# Runs prettier --write on the modified file if it's a supported type
# and prettier is available in the project.

set -euo pipefail

# Read the hook payload from stdin
payload=$(cat)

# Extract the file path from the tool input (works for both Edit and Write)
file_path=$(echo "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

# No file path — nothing to do
if [ -z "$file_path" ]; then
  exit 0
fi

# Only format supported file types
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.md|*.css|*.scss|*.html|*.yml|*.yaml)
    ;;
  *)
    exit 0
    ;;
esac

# File must exist (it should, since the tool just wrote it)
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

# No package.json found — prettier isn't available, skip silently
if [ -z "$project_root" ]; then
  exit 0
fi

# Check if prettier is available in this project
if [ ! -x "$project_root/node_modules/.bin/prettier" ]; then
  # Prettier isn't installed — skip silently so we don't break projects without it
  exit 0
fi

# Run prettier on the file, suppressing output on success
# On failure, let the error show so Claude can see and fix formatting issues
if ! "$project_root/node_modules/.bin/prettier" --write "$file_path" >/dev/null 2>&1; then
  echo "Prettier formatting failed for $file_path" >&2
  "$project_root/node_modules/.bin/prettier" --write "$file_path" >&2 || true
  exit 1
fi

exit 0
