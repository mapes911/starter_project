#!/usr/bin/env bash
# PostToolUse hook: log all Bash commands to a local file.
#
# Receives JSON on stdin with structure:
#   { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }

set -euo pipefail

payload=$(cat)
cmd=$(echo "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)

if [ -z "$cmd" ]; then
  exit 0
fi

printf '%s %s\n' "$(date -Is)" "$cmd" >> .claude/command-log.txt
exit 0
