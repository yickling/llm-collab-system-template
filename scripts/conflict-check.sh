#!/bin/bash
# conflict-check.sh
#
# Pre-merge conflict detection script.
# Compares the current branch's changed files against other active branches
# and against file ownership declared in ACTIVE_SESSIONS.md.
#
# Usage: ./scripts/conflict-check.sh [base-branch]
#   base-branch: branch to compare against (default: main)
#
# Exit codes:
#   0 - No conflicts detected
#   1 - Potential conflicts found
#   2 - Script error

set -euo pipefail

BASE_BRANCH="${1:-main}"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
ACTIVE_SESSIONS="docs/memory/ACTIVE_SESSIONS.md"

if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    echo "ERROR: You are on the base branch ($BASE_BRANCH). Switch to a feature branch first."
    exit 2
fi

echo "=== Conflict Check ==="
echo "Current branch: $CURRENT_BRANCH"
echo "Base branch:    $BASE_BRANCH"
echo ""

# Get files changed on this branch relative to base
CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || git diff --name-only "$BASE_BRANCH"..HEAD 2>/dev/null)

if [ -z "$CHANGED_FILES" ]; then
    echo "No files changed on this branch relative to $BASE_BRANCH."
    exit 0
fi

echo "Files changed on this branch:"
echo "$CHANGED_FILES" | sed 's/^/  /'
echo ""

CONFLICTS_FOUND=0

# --- Check 1: Compare against ACTIVE_SESSIONS.md file ownership ---
if [ -f "$ACTIVE_SESSIONS" ]; then
    echo "--- Checking against ACTIVE_SESSIONS.md ---"

    # Parse active sessions (skip header rows, comments, and empty lines)
    # Expected format: | Developer | Branch | Scope | Files Owned | Started (UTC) | Status |
    while IFS='|' read -r _ developer branch scope files_owned _ status _; do
        # Trim whitespace
        developer=$(echo "$developer" | xargs 2>/dev/null || true)
        branch=$(echo "$branch" | xargs 2>/dev/null || true)
        files_owned=$(echo "$files_owned" | xargs 2>/dev/null || true)
        status=$(echo "$status" | xargs 2>/dev/null || true)

        # Skip non-data rows
        [ -z "$developer" ] && continue
        [ "$developer" = "Developer" ] && continue
        [[ "$developer" == -* ]] && continue
        [[ "$developer" == \<* ]] && continue

        # Only check ACTIVE sessions on other branches
        [ "$status" != "ACTIVE" ] && continue
        [ "$branch" = "$CURRENT_BRANCH" ] && continue

        # Check each owned file pattern against our changed files
        IFS=',' read -ra PATTERNS <<< "$files_owned"
        for pattern in "${PATTERNS[@]}"; do
            pattern=$(echo "$pattern" | xargs 2>/dev/null || true)
            [ -z "$pattern" ] && continue

            # Convert glob pattern to grep-compatible regex
            regex=$(echo "$pattern" | sed 's/\*/\.\*/g')

            MATCHES=$(echo "$CHANGED_FILES" | grep -E "^$regex$" 2>/dev/null || true)
            if [ -n "$MATCHES" ]; then
                echo "CONFLICT: $developer ($branch) owns '$pattern' and you changed:"
                echo "$MATCHES" | sed 's/^/  /'
                CONFLICTS_FOUND=1
            fi
        done
    done < "$ACTIVE_SESSIONS"

    if [ "$CONFLICTS_FOUND" -eq 0 ]; then
        echo "No file ownership conflicts found."
    fi
else
    echo "WARN: $ACTIVE_SESSIONS not found. Skipping ownership check."
fi

echo ""

# --- Check 2: Compare against other active branches ---
echo "--- Checking against other active branches ---"

REMOTE_BRANCHES=$(git branch -r --list "origin/*" 2>/dev/null | grep -v "origin/$BASE_BRANCH" | grep -v "origin/HEAD" | sed 's/^ *//' || true)

BRANCH_CONFLICTS=0
for remote_branch in $REMOTE_BRANCHES; do
    local_name=$(echo "$remote_branch" | sed 's|^origin/||')
    [ "$local_name" = "$CURRENT_BRANCH" ] && continue

    OTHER_CHANGED=$(git diff --name-only "$BASE_BRANCH"..."$remote_branch" 2>/dev/null || true)
    [ -z "$OTHER_CHANGED" ] && continue

    OVERLAPPING=$(comm -12 <(echo "$CHANGED_FILES" | sort) <(echo "$OTHER_CHANGED" | sort) 2>/dev/null || true)

    if [ -n "$OVERLAPPING" ]; then
        echo "CONFLICT: Branch '$local_name' also modifies:"
        echo "$OVERLAPPING" | sed 's/^/  /'
        BRANCH_CONFLICTS=1
        CONFLICTS_FOUND=1
    fi
done

if [ "$BRANCH_CONFLICTS" -eq 0 ]; then
    echo "No branch-level file conflicts found."
fi

echo ""

# --- Summary ---
if [ "$CONFLICTS_FOUND" -eq 1 ]; then
    echo "=== CONFLICTS DETECTED ==="
    echo "Coordinate with the other developer(s) before merging."
    exit 1
else
    echo "=== No conflicts detected. Safe to merge. ==="
    exit 0
fi
