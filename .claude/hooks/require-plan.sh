#!/usr/bin/env bash
# UserPromptSubmit hook: remind Claude to plan before implementing features.
#
# Receives JSON on stdin with structure:
#   { "prompt": "the user's message", ... }
#
# Detects feature-request language and injects a reminder to use plan mode.

set -euo pipefail

payload=$(cat)
prompt=$(echo "$payload" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)

# Convert to lowercase for matching
prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# Skip short messages (likely follow-ups, confirmations, or quick questions)
if [ ${#prompt_lower} -lt 30 ]; then
  exit 0
fi

# Skip messages that are already about planning or committing
if echo "$prompt_lower" | grep -qiE "^(commit|push|yes|no|ok|sure|thanks|let.s do|looks good|lgtm|approve|/commit|/plan|git status)"; then
  exit 0
fi

# Match feature-request language
feature_patterns="(add|create|build|implement|set up|introduce|develop|make a|make the|write a|new feature|new component|new endpoint|new api|new page|refactor|redesign|rework|overhaul|migrate)"

if echo "$prompt_lower" | grep -qiE "$feature_patterns"; then
  echo "This looks like a feature request. Before implementing, consider using plan mode (EnterPlanMode) to think through the approach, identify affected files, and get user alignment." >&2
  exit 0
fi

exit 0
