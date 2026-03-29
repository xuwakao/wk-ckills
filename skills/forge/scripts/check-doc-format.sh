#!/usr/bin/env bash
# check-doc-format.sh
# Validate documentation format in docs/ directory.
# Checks for required fields, timestamps, cross-references, and quality.
#
# Usage: bash check-doc-format.sh [docs_dir]
# Exit codes:
#   0 - all checks passed
#   1 - validation errors found

set -euo pipefail

DOCS_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}/docs}"
ERRORS=0

if [ ! -d "$DOCS_DIR" ]; then
    echo "ERROR: docs/ directory not found at ${DOCS_DIR}"
    exit 1
fi

echo "Validating documentation in ${DOCS_DIR}..."
echo ""

# --- Plan documents ---
if [ -d "${DOCS_DIR}/plan" ]; then
    for f in "${DOCS_DIR}/plan"/*.md; do
        [ -f "$f" ] || continue
        BASENAME=$(basename "$f")

        # Check required fields
        if ! grep -q '^Status:' "$f"; then
            echo "ERROR [plan/${BASENAME}]: Missing 'Status:' field"
            ERRORS=$((ERRORS + 1))
        fi
        if ! grep -q '^Created:' "$f"; then
            echo "ERROR [plan/${BASENAME}]: Missing 'Created:' field"
            ERRORS=$((ERRORS + 1))
        fi
        if ! grep -q '^Source:' "$f"; then
            echo "WARN  [plan/${BASENAME}]: Missing 'Source:' field (required for traceability)"
        fi
        if ! grep -q '## Phases' "$f" && ! grep -q '### Phase' "$f"; then
            echo "WARN  [plan/${BASENAME}]: No 'Phases' section found"
        fi
        if ! grep -q '## Findings' "$f"; then
            echo "WARN  [plan/${BASENAME}]: No 'Findings' section found"
        fi
        if ! grep -q '## Alternatives' "$f"; then
            echo "WARN  [plan/${BASENAME}]: No 'Alternatives & Trade-offs' section found"
        fi
    done
fi

# --- Progress documents ---
if [ -d "${DOCS_DIR}/progress" ]; then
    for f in "${DOCS_DIR}/progress"/*.md; do
        [ -f "$f" ] || continue
        BASENAME=$(basename "$f")

        if ! grep -q '^Created:' "$f"; then
            echo "ERROR [progress/${BASENAME}]: Missing 'Created:' field"
            ERRORS=$((ERRORS + 1))
        fi
        if ! grep -q '^Source:' "$f"; then
            echo "WARN  [progress/${BASENAME}]: Missing 'Source:' field"
        fi
        if ! grep -q '## Log' "$f"; then
            echo "WARN  [progress/${BASENAME}]: No 'Log' section found"
        fi
        if ! grep -q '## Findings' "$f"; then
            echo "WARN  [progress/${BASENAME}]: No 'Findings' section found"
        fi
    done
fi

# --- Issue documents ---
if [ -d "${DOCS_DIR}/issue" ]; then
    for f in "${DOCS_DIR}/issue"/*.md; do
        [ -f "$f" ] || continue
        BASENAME=$(basename "$f")

        if ! grep -q '^Created:' "$f"; then
            echo "ERROR [issue/${BASENAME}]: Missing 'Created:' field"
            ERRORS=$((ERRORS + 1))
        fi
        if ! grep -q '## Findings' "$f"; then
            echo "WARN  [issue/${BASENAME}]: No 'Findings' section found"
        fi

        # Check for issues without root cause
        OPEN_WITHOUT_RC=$(grep -c 'IN-PROGRESS' "$f" 2>/dev/null || echo 0)
        if [ "$OPEN_WITHOUT_RC" -gt 0 ]; then
            echo "INFO  [issue/${BASENAME}]: ${OPEN_WITHOUT_RC} issue(s) still IN-PROGRESS"
        fi
    done
fi

# --- Cross-document checks ---
# Check for unverified findings
UNVERIFIED=$(grep -rl '\[UNVERIFIED\]' "$DOCS_DIR" 2>/dev/null | wc -l | tr -d ' ' || true)
if [ "${UNVERIFIED:-0}" -gt 0 ]; then
    echo ""
    echo "INFO: ${UNVERIFIED} file(s) contain unverified findings [UNVERIFIED]:"
    grep -rl '\[UNVERIFIED\]' "$DOCS_DIR" 2>/dev/null | while read -r uf; do
        echo "  - $(echo "$uf" | sed "s|${DOCS_DIR}/||")"
    done
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "RESULT: ${ERRORS} error(s) found. Fix required fields before proceeding."
    exit 1
else
    echo "RESULT: All required checks passed."
    exit 0
fi
