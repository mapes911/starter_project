#!/usr/bin/env bash
# Stop hook: remind Claude to add/update tests when source files were modified.
#
# Checks if source files were changed without corresponding test changes.
# Runs when Claude finishes a task, before the user sees the response.

set -euo pipefail

# Check for modified source files (staged and unstaged)
changed_src=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|tsx)$' | grep -v '__tests__\|\.test\.\|\.spec\.' || true)

# Check for modified test files
changed_tests=$(git diff --name-only HEAD 2>/dev/null | grep -E '(__tests__/.*\.(ts|tsx)$|\.test\.(ts|tsx)$|\.spec\.(ts|tsx)$)' || true)

# No source changes — nothing to remind about
if [ -z "$changed_src" ]; then
  exit 0
fi

# Source changed but no tests changed — remind
if [ -z "$changed_tests" ]; then
  echo "Source files were modified but no tests were added or updated. Consider adding or updating tests for the changes made." >&2
  exit 0
fi

exit 0
