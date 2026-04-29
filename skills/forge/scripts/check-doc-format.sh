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
        # A.0 Requirements section
        if ! grep -q '## Requirements' "$f"; then
            echo "ERROR [plan/${BASENAME}]: No 'Requirements' section found (required per META-PHASE A.0)"
            ERRORS=$((ERRORS + 1))
        else
            REQ_SECTION=$(sed -n '/## Requirements/,/^## /p' "$f" 2>/dev/null || true)
            if ! echo "$REQ_SECTION" | grep -qE '\|\s*AC-[0-9]+\s*\|'; then
                echo "ERROR [plan/${BASENAME}]: Requirements section has no AC-N acceptance criteria rows"
                ERRORS=$((ERRORS + 1))
            fi
        fi

        # A.1 Codebase Reconnaissance section
        if ! grep -q '## Codebase Reconnaissance' "$f"; then
            echo "ERROR [plan/${BASENAME}]: No 'Codebase Reconnaissance' section found (required per META-PHASE A.1)"
            ERRORS=$((ERRORS + 1))
        else
            RECON_SECTION=$(sed -n '/## Codebase Reconnaissance/,/^## /p' "$f" 2>/dev/null || true)
            if ! echo "$RECON_SECTION" | grep -qE '\|\s*S[0-9]+\s*\|'; then
                echo "ERROR [plan/${BASENAME}]: Codebase Reconnaissance has no S# search action rows"
                ERRORS=$((ERRORS + 1))
            fi
        fi

        # A.2 Stage 0 Prior Art Survey
        if grep -q '## Architecture Decision' "$f"; then
            ADR_SECTION_FULL=$(sed -n '/## Architecture Decision/,/^## /p' "$f" 2>/dev/null || true)
            if ! echo "$ADR_SECTION_FULL" | grep -q '### Prior Art Survey'; then
                echo "ERROR [plan/${BASENAME}]: Architecture Decision has no 'Prior Art Survey' subsection (required per A.2 Stage 0)"
                ERRORS=$((ERRORS + 1))
            elif ! echo "$ADR_SECTION_FULL" | grep -qE '\|\s*P[0-9]+\s*\|'; then
                echo "WARN  [plan/${BASENAME}]: Prior Art Survey has no P# rows — was the survey actually conducted?"
            fi
        fi

        # Anti-Guessing — flag unresolved [GUESS] markers
        GUESS_COUNT=$(grep -c '\[GUESS\]' "$f" 2>/dev/null | head -1 || true)
        GUESS_COUNT=${GUESS_COUNT:-0}
        if [ "$GUESS_COUNT" -gt 0 ]; then
            echo "WARN  [plan/${BASENAME}]: ${GUESS_COUNT} unresolved [GUESS] marker(s) — must be verified before relying on these claims"
        fi

        # A.2 Architecture Decision section
        if ! grep -q '## Architecture Decision' "$f"; then
            echo "ERROR [plan/${BASENAME}]: No 'Architecture Decision' section found (required per META-PHASE A.2)"
            ERRORS=$((ERRORS + 1))
        else
            ADR_SECTION=$(sed -n '/## Architecture Decision/,/^## /p' "$f" 2>/dev/null || true)
            if ! echo "$ADR_SECTION" | grep -qE '\*\*ADR ID\*\*:\s*ADR-[0-9]+'; then
                echo "WARN  [plan/${BASENAME}]: Architecture Decision has no concrete ADR-NNN id (placeholder not replaced?)"
            fi
            if ! echo "$ADR_SECTION" | grep -qE '\*\*Status\*\*:\s*(PROPOSED|ACCEPTED|SUPERSEDED|DEPRECATED)'; then
                echo "WARN  [plan/${BASENAME}]: Architecture Decision has no valid Status (PROPOSED/ACCEPTED/SUPERSEDED/DEPRECATED)"
            fi
        fi

        # A.3 Feasibility Research section
        if ! grep -q '## Feasibility Research' "$f"; then
            echo "ERROR [plan/${BASENAME}]: No 'Feasibility Research' section found (required per META-PHASE A.3)"
            ERRORS=$((ERRORS + 1))
        else
            FEAS_SECTION=$(sed -n '/## Feasibility Research/,/^## /p' "$f" 2>/dev/null || true)
            if ! echo "$FEAS_SECTION" | grep -qE '\|\s*A[0-9]+\s*\|'; then
                echo "ERROR [plan/${BASENAME}]: Feasibility Research section has no A# assumption rows"
                ERRORS=$((ERRORS + 1))
            fi
            if echo "$FEAS_SECTION" | grep -qE '\|\s*(REJECTED|INCONCLUSIVE)\s*\|'; then
                echo "WARN  [plan/${BASENAME}]: Feasibility Research contains REJECTED or INCONCLUSIVE assumptions — the plan should be reworked before execution"
            fi
        fi

        # A.4/A.5 Phases and Test Plan
        if ! grep -q '## Phases' "$f" && ! grep -q '### Phase' "$f"; then
            echo "WARN  [plan/${BASENAME}]: No 'Phases' section found"
        fi
        if grep -q '### Phase' "$f"; then
            if ! grep -q '#### Phase' "$f" || ! grep -q 'Test Plan' "$f"; then
                echo "WARN  [plan/${BASENAME}]: Phase found but no 'Test Plan' subsection (required per META-PHASE A.5)"
            fi
            if ! grep -qiE 'AC coverage' "$f"; then
                echo "WARN  [plan/${BASENAME}]: Phase has no 'AC coverage' field linking to AC-N"
            fi
        fi

        if ! grep -q '## Findings' "$f"; then
            echo "WARN  [plan/${BASENAME}]: No 'Findings' section found"
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
        OPEN_WITHOUT_RC=$(grep -c 'IN-PROGRESS' "$f" 2>/dev/null | head -1 || true)
        OPEN_WITHOUT_RC=${OPEN_WITHOUT_RC:-0}
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
