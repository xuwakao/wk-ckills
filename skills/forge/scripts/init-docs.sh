#!/usr/bin/env bash
# init-docs.sh
# Initialize the docs/ directory structure in the project directory.
# Copies templates from the plugin's templates/ directory.
#
# Usage: bash init-docs.sh [project_dir]
# If project_dir is not specified, uses CLAUDE_PROJECT_DIR or current directory.

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
TEMPLATES_DIR="${PLUGIN_ROOT}/skills/forge/templates"
DOCS_DIR="${PROJECT_DIR}/docs"

# Create directory structure
mkdir -p "${DOCS_DIR}/plan" "${DOCS_DIR}/progress" "${DOCS_DIR}/issue"

# Create .forge-counter to activate forge hooks
COUNTER_FILE="${PROJECT_DIR}/.forge-counter"
if [ ! -f "$COUNTER_FILE" ]; then
    printf '0\n0\n' > "$COUNTER_FILE"
    echo "Created .forge-counter (forge hooks activated)"
fi

echo "docs/ directory structure created at: ${DOCS_DIR}"
echo "  docs/plan/     — plan documents"
echo "  docs/progress/ — progress logs"
echo "  docs/issue/    — issue tracking"

# Add .forge-counter to .gitignore if not already present
GITIGNORE="${PROJECT_DIR}/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -qF '.forge-counter' "$GITIGNORE"; then
        echo '.forge-counter' >> "$GITIGNORE"
        echo "Added .forge-counter to .gitignore"
    fi
else
    echo '.forge-counter' > "$GITIGNORE"
    echo "Created .gitignore with .forge-counter"
fi

echo ""
echo "Templates available at: ${TEMPLATES_DIR}"
echo "  plan.md     — use for new plan documents"
echo "  progress.md — use for new progress logs"
echo "  issue.md    — use for new issue trackers"
echo ""
echo "Initialization complete. Proceed to META-PHASE A (planning)."
