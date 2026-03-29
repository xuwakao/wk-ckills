#!/usr/bin/env bash
# pre-tool-use-guard.sh
# L1: Periodic rules injection into Claude's context
# L2: Behavioral detection - check if docs/ is being maintained
#
# Triggered by: PreToolUse (every tool call, plugin-level hook)
# Self-guard: exits immediately if /forge workflow is not active
# Exit codes:
#   0 - proceed normally (may output rules reminder to stdout)
#   2 - block the tool call (docs maintenance violation)

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
COUNTER_FILE="${PROJECT_DIR}/.forge-counter"
RULES_FILE="${PLUGIN_ROOT}/skills/forge/references/rules-compact.md"
DOCS_DIR="${PROJECT_DIR}/docs"

# --- Self-guard: only run if /forge workflow is active ---
# Forge is active only if .forge-counter exists (created by init-docs.sh)
if [ ! -f "$COUNTER_FILE" ]; then
    exit 0
fi

# --- Configuration ---
L1_INTERVAL=10          # Inject rules every N tool calls
L2_THRESHOLD=30         # Warn if docs/ not updated after N tool calls
L2_BLOCK_THRESHOLD=50   # Block if docs/ not updated after N tool calls

# --- Counter Management ---
# Counter file format: two lines
#   Line 1: total tool call count
#   Line 2: tool call count since last docs/ update
# File is guaranteed to exist here (self-guard above + init-docs.sh creates it)

TOTAL_COUNT=$(sed -n '1p' "$COUNTER_FILE")
SINCE_DOCS_COUNT=$(sed -n '2p' "$COUNTER_FILE")

TOTAL_COUNT=$((TOTAL_COUNT + 1))
SINCE_DOCS_COUNT=$((SINCE_DOCS_COUNT + 1))

# --- L2: Check if docs/ was recently updated ---
# Reset since_docs counter if any file in docs/ was modified after counter file
if [ -d "$DOCS_DIR" ]; then
    COUNTER_MTIME=$(stat -f %m "$COUNTER_FILE" 2>/dev/null || stat -c %Y "$COUNTER_FILE" 2>/dev/null || echo 0)
    LATEST_DOC_MTIME=0
    while IFS= read -r -d '' docfile; do
        DOC_MTIME=$(stat -f %m "$docfile" 2>/dev/null || stat -c %Y "$docfile" 2>/dev/null || echo 0)
        if [ "$DOC_MTIME" -gt "$LATEST_DOC_MTIME" ]; then
            LATEST_DOC_MTIME=$DOC_MTIME
        fi
    done < <(find "$DOCS_DIR" -name '*.md' -print0 2>/dev/null)

    if [ "$LATEST_DOC_MTIME" -gt "$COUNTER_MTIME" ]; then
        SINCE_DOCS_COUNT=0
    fi
fi

# Write updated counters
printf '%d\n%d\n' "$TOTAL_COUNT" "$SINCE_DOCS_COUNT" > "$COUNTER_FILE"

# --- L1: Periodic rules injection ---
if [ $((TOTAL_COUNT % L1_INTERVAL)) -eq 0 ] && [ -f "$RULES_FILE" ]; then
    echo "======== /forge WORKFLOW RULES REFRESH (call #${TOTAL_COUNT}) ========"
    cat "$RULES_FILE"
    echo "======== END RULES REFRESH ========"
fi

# --- L2: Behavioral detection ---
if [ -d "$DOCS_DIR" ]; then
    if [ "$SINCE_DOCS_COUNT" -ge "$L2_BLOCK_THRESHOLD" ]; then
        echo "ERROR: docs/ has not been updated for ${SINCE_DOCS_COUNT} tool calls (threshold: ${L2_BLOCK_THRESHOLD})." >&2
        echo "Update docs/progress/ or docs/issue/ before continuing." >&2
        exit 2
    elif [ "$SINCE_DOCS_COUNT" -ge "$L2_THRESHOLD" ]; then
        echo "WARNING: docs/ has not been updated for ${SINCE_DOCS_COUNT} tool calls. Update documentation per /forge workflow rules."
    fi
fi

exit 0
