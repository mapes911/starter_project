#!/usr/bin/env bash
# PreToolUse hook: block dangerous Bash commands before they run.
#
# Receives JSON on stdin with structure:
#   { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }
#
# Exits with code 2 to block the command and feed the error back to Claude.

set -euo pipefail

# Read the hook payload and extract the command field via sed.
# This matches "command": "..." and captures everything between the quotes.
payload=$(cat)
cmd=$(echo "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)

# No command — nothing to check
if [ -z "$cmd" ]; then
  exit 0
fi

dangerous_patterns=(
  "rm -rf"
  "git reset --hard"
  "git push.*--force"
  "DROP TABLE"
  "DROP DATABASE"
  "curl.*\|.*sh"
  "wget.*\|.*bash"
)

for pattern in "${dangerous_patterns[@]}"; do
  if echo "$cmd" | grep -qiE "$pattern"; then
    echo "Blocked: '$cmd' matches dangerous pattern '$pattern'. Propose a safer alternative." >&2
    exit 2
  fi
done

exit 0
