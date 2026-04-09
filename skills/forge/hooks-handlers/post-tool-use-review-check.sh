#!/usr/bin/env bash
# post-tool-use-review-check.sh
# Validates review artifacts when a phase is marked COMPLETE in plan docs.
# Also checks review quality (table structure, verdicts, evidence).
#
# Triggered by: PostToolUse (matcher: Write|Edit)
# Self-guard: exits immediately if /forge workflow is not active
# SAFETY: This script NEVER exits with code 2 (never blocks).
# Exit codes:
#   0 - always (may output ACTION REQUIRED instructions to stdout)

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

for planfile in "$PLAN_DIR"/*.md; do
    [ -f "$planfile" ] || continue
    PLAN_NAME=$(basename "$planfile" .md)

    PROGRESS_FILE="$PROGRESS_DIR/${PLAN_NAME}.md"
    if [ ! -f "$PROGRESS_FILE" ]; then
        continue
    fi

    PHASE_NUM=0
    while IFS= read -r line; do
        # Track current phase number from "### Phase N:" headers
        if echo "$line" | grep -qE '^###\s+Phase\s+[0-9]+'; then
            PHASE_NUM=$(echo "$line" | grep -oE '[0-9]+' | head -1 || true)
        fi

        # Match "**Status**: COMPLETE" or "Status: COMPLETE" patterns only
        if [ "$PHASE_NUM" -gt 0 ] && echo "$line" | grep -qiE '(\*\*)?Status(\*\*)?:\s*COMPLETE'; then

            # Check 1a: Outcome Review entry exists
            if ! grep -q "### Review: Phase ${PHASE_NUM} — Outcome" "$PROGRESS_FILE" 2>/dev/null; then
                echo "ACTION REQUIRED: Phase ${PHASE_NUM} is marked COMPLETE in plan/${PLAN_NAME}.md but has no '### Review: Phase ${PHASE_NUM} — Outcome' in progress/${PLAN_NAME}.md. Write the C.3a outcome review table (expected vs actual) before marking COMPLETE."
            fi

            # Check 1b: Code Review entry exists
            if ! grep -q "### Review: Phase ${PHASE_NUM} — Code" "$PROGRESS_FILE" 2>/dev/null; then
                echo "ACTION REQUIRED: Phase ${PHASE_NUM} is marked COMPLETE in plan/${PLAN_NAME}.md but has no '### Review: Phase ${PHASE_NUM} — Code' in progress/${PLAN_NAME}.md. Write the C.3b code review table (logic/edge cases/error handling/performance/quality/workarounds/style) before marking COMPLETE."
            fi

            if grep -q "### Review: Phase ${PHASE_NUM}" "$PROGRESS_FILE" 2>/dev/null; then
                # Extract relevant review sections
                REVIEW_SECTION=$(sed -n "/### Review: Phase ${PHASE_NUM}/,/^### /p" "$PROGRESS_FILE" 2>/dev/null | head -60 || true)

                # Check 2: Review has verdict table rows
                if ! echo "$REVIEW_SECTION" | grep -qE '\|\s*(PASS|FAIL|PARTIAL|CONCERN)'; then
                    echo "ACTION REQUIRED: Review for Phase ${PHASE_NUM} in progress/${PLAN_NAME}.md has no PASS/FAIL/PARTIAL/CONCERN verdicts. Add a table with one row per item, each with a concrete verdict and evidence."
                fi

                # Check 3: Review has Overall Verdict
                if ! echo "$REVIEW_SECTION" | grep -qiE 'Overall\s+Verdict'; then
                    echo "ACTION REQUIRED: Review for Phase ${PHASE_NUM} in progress/${PLAN_NAME}.md is missing an Overall Verdict line."
                fi

                # Check 4: Check for vague evidence patterns
                if echo "$REVIEW_SECTION" | grep -qiE '\|\s*(it works|works fine|looks good|done|completed|ok)\s*\|'; then
                    echo "ACTION REQUIRED: Review for Phase ${PHASE_NUM} has vague evidence. Replace with concrete file paths, command outputs, or test results."
                fi
            fi

            PHASE_NUM=0
        fi
    done < "$planfile"
done

exit 0
