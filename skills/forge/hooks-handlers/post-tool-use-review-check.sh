#!/usr/bin/env bash
# post-tool-use-review-check.sh
# Validates review artifacts when a phase is marked COMPLETE in plan docs.
#
# Triggered by: PostToolUse (matcher: Write|Edit)
# Self-guard: exits immediately if /forge workflow is not active
# SAFETY: This script NEVER exits with code 2 (never blocks).
# Exit codes:
#   0 - always (may output warnings to stdout)

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
COUNTER_FILE="${PROJECT_DIR}/.forge-counter"
DOCS_DIR="${PROJECT_DIR}/docs"
PLAN_DIR="${DOCS_DIR}/plan"
PROGRESS_DIR="${DOCS_DIR}/progress"

# --- Self-guard ---
if [ ! -f "$COUNTER_FILE" ]; then
    exit 0
fi

if [ ! -d "$PLAN_DIR" ] || [ ! -d "$PROGRESS_DIR" ]; then
    exit 0
fi

# --- Check for phases marked COMPLETE without review artifacts ---
# Scan all plan files for COMPLETE phases, then verify progress has matching reviews

WARNINGS=""

for planfile in "$PLAN_DIR"/*.md; do
    [ -f "$planfile" ] || continue
    PLAN_NAME=$(basename "$planfile" .md)

    # Find progress file with same name
    PROGRESS_FILE="$PROGRESS_DIR/${PLAN_NAME}.md"
    if [ ! -f "$PROGRESS_FILE" ]; then
        continue
    fi

    # Extract phase numbers marked as COMPLETE (or Status: COMPLETE)
    # Match patterns like "**Status**: COMPLETE" or "Status: COMPLETE"
    PHASE_NUM=0
    while IFS= read -r line; do
        # Track current phase number from "### Phase N:" headers
        if echo "$line" | grep -qE '^###\s+Phase\s+[0-9]+'; then
            PHASE_NUM=$(echo "$line" | grep -oE '[0-9]+' | head -1)
        fi
        # Check if this line marks a phase status as COMPLETE
        # Match "**Status**: COMPLETE" or "Status: COMPLETE" patterns only
        if [ "$PHASE_NUM" -gt 0 ] && echo "$line" | grep -qiE '(\*\*)?Status(\*\*)?:\s*COMPLETE'; then
            # Verify progress has "### Review: Phase N"
            if ! grep -q "### Review: Phase ${PHASE_NUM}" "$PROGRESS_FILE" 2>/dev/null; then
                WARNINGS="${WARNINGS}WARNING: Phase ${PHASE_NUM} is marked COMPLETE in plan/${PLAN_NAME}.md but no '### Review: Phase ${PHASE_NUM}' found in progress/${PLAN_NAME}.md. Per RULE 3 C.3, a review table is required before marking COMPLETE.\n"
            else
                # Check if review has a table (at least one | row with PASS/FAIL/PARTIAL)
                # Extract the review section and check for verdict rows
                if ! grep -A 20 "### Review: Phase ${PHASE_NUM}" "$PROGRESS_FILE" 2>/dev/null | grep -qE '\|\s*(PASS|FAIL|PARTIAL)'; then
                    WARNINGS="${WARNINGS}WARNING: Review for Phase ${PHASE_NUM} in progress/${PLAN_NAME}.md exists but has no PASS/FAIL/PARTIAL verdicts. The review table may be incomplete.\n"
                fi
            fi
            PHASE_NUM=0  # Reset after checking
        fi
    done < "$planfile"
done

if [ -n "$WARNINGS" ]; then
    printf "%b" "$WARNINGS"
fi

exit 0
