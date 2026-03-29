#!/usr/bin/env bash
# stop-guard.sh
# L4: Prevent Claude from self-stopping when workflow is still active
#
# Triggered by: Stop event (plugin-level hook)
# Self-guard: exits immediately if /forge workflow is not active
# Exit codes:
#   0 - allow stop (plan completed/paused/deprecated, or no active workflow)
#   2 - block stop (plan still ACTIVE, force Claude to continue)

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DOCS_DIR="${PROJECT_DIR}/docs"
PLAN_DIR="${DOCS_DIR}/plan"

# --- Self-guard: only run if /forge workflow is active ---
# Forge is active only if .forge-counter exists (created by init-docs.sh)
COUNTER_FILE="${PROJECT_DIR}/.forge-counter"
if [ ! -f "$COUNTER_FILE" ]; then
    exit 0
fi

# No plan directory, allow stop
if [ ! -d "$PLAN_DIR" ]; then
    exit 0
fi

# Find the most recently modified plan file
LATEST_PLAN=""
LATEST_MTIME=0
while IFS= read -r -d '' planfile; do
    MTIME=$(stat -f %m "$planfile" 2>/dev/null || stat -c %Y "$planfile" 2>/dev/null || echo 0)
    if [ "$MTIME" -gt "$LATEST_MTIME" ]; then
        LATEST_MTIME=$MTIME
        LATEST_PLAN=$planfile
    fi
done < <(find "$PLAN_DIR" -name '*.md' -print0 2>/dev/null)

# No plan files found, allow stop
if [ -z "$LATEST_PLAN" ]; then
    exit 0
fi

# Check plan status
PLAN_STATUS=$(grep -m1 '^Status:' "$LATEST_PLAN" 2>/dev/null | sed 's/^Status:[[:space:]]*//' || echo "")

case "$PLAN_STATUS" in
    ACTIVE)
        echo "BLOCKED: /forge workflow is still ACTIVE ($(basename "$LATEST_PLAN"))." >&2
        echo "Continue executing the next phase. Do not stop." >&2
        echo "To pause: mark the plan Status as PAUSED, or the user can press ESC/Ctrl+C." >&2
        exit 2
        ;;
    COMPLETED|PAUSED|DEPRECATED)
        # Check for unresolved issues (non-blocking reminder)
        ISSUE_DIR="${DOCS_DIR}/issue"
        if [ -d "$ISSUE_DIR" ]; then
            OPEN_ISSUES=$(grep -rl 'IN-PROGRESS\|BLOCKED' "$ISSUE_DIR" 2>/dev/null | wc -l | tr -d ' ' || true)
            if [ "${OPEN_ISSUES:-0}" -gt 0 ]; then
                echo "REMINDER: ${OPEN_ISSUES} issue file(s) contain unresolved items (IN-PROGRESS or BLOCKED). Consider addressing them."
            fi
        fi
        # Check for unverified findings (non-blocking reminder)
        UNVERIFIED=$(grep -rl '\[UNVERIFIED\]' "$DOCS_DIR" 2>/dev/null | wc -l | tr -d ' ' || true)
        if [ "${UNVERIFIED:-0}" -gt 0 ]; then
            echo "REMINDER: ${UNVERIFIED} file(s) contain unverified findings [UNVERIFIED]. Consider verifying them."
        fi
        exit 0
        ;;
    *)
        # Unknown or missing status, allow stop but warn
        echo "WARNING: Plan status is '${PLAN_STATUS:-empty}' in $(basename "$LATEST_PLAN"). Expected: ACTIVE, COMPLETED, PAUSED, or DEPRECATED."
        exit 0
        ;;
esac
