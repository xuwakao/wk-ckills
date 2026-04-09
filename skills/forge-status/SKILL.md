---
name: forge-status
description: >
  Verify that the /forge workflow is still active and that you are still
  following its rules. Use when the user wants to check if the assistant
  has retained the forge workflow state in a long conversation.
version: 1.0.0
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# /forge Status Check

Execute these steps in order. Do not skip any.

## Step 1: Re-read the forge rules

Read the full SKILL.md to refresh the workflow rules in your context:
```
${CLAUDE_PLUGIN_ROOT}/skills/forge/SKILL.md
```

## Step 2: Check forge activation state

Run:
```bash
test -f "${CLAUDE_PROJECT_DIR:-.}/.forge-counter" && echo "ACTIVE" || echo "INACTIVE"
cat "${CLAUDE_PROJECT_DIR:-.}/.forge-counter" 2>/dev/null
```

Report:
- **Activation**: ACTIVE / INACTIVE (whether `.forge-counter` exists)
- **Counter values**: total tool calls, calls since last docs/ update

## Step 3: Scan docs/ state

Use Glob to list files in `docs/plan/`, `docs/progress/`, `docs/issue/`. For each plan file, extract its `Status:` field.

Report:
- **Plans**: list each `<name>.md` with its status (ACTIVE / COMPLETED / PAUSED / DEPRECATED)
- **Progress files**: list each `<name>.md` and the latest review entry header (if any)
- **Open issues**: count of issues with `IN-PROGRESS` or `BLOCKED` status across all files in `docs/issue/`
- **Unverified findings**: count of `[UNVERIFIED]` markers across all docs

## Step 4: Compliance self-check

Answer these questions truthfully based on the current conversation context:

1. **Current phase**: which phase of which plan are you currently in? (META-PHASE A/B/C.N/D, or RULE 7)
2. **Last review artifact**: when did you last produce a `### Plan Review` or `### Review: Phase N` table? Cite the location.
3. **Pending review actions**: are there any phases marked COMPLETE without a corresponding review entry? Are there any open FAIL/PARTIAL items not yet addressed?
4. **Findings recording**: have you recorded any findings during the current phase's execution? If 0, is that genuinely because nothing non-obvious was discovered?
5. **Diagnosis discipline**: if there are any open issues, do they have a Diagnosis table with at least 2 verified hypotheses?

## Step 5: Output report

Format the output as:

```
=== /forge STATUS REPORT ===

Activation: [ACTIVE/INACTIVE]
Counter: [total / since-docs]

Plans:
  - <name>.md: <Status>

Progress:
  - <name>.md: latest review = <header or "none">

Open issues: <count>
Unverified findings: <count>

Compliance self-check:
  Current phase:        <answer>
  Last review artifact: <answer>
  Pending actions:      <answer>
  Findings this phase:  <answer>
  Diagnosis discipline: <answer>

Verdict: [COMPLIANT / DRIFT DETECTED]
```

If any compliance answer indicates a violation (skipped review, missing diagnosis, untracked findings), set Verdict to **DRIFT DETECTED** and list the specific corrective actions needed.

Do NOT proceed to execute any corrective actions automatically — just report. The user will decide whether to continue the workflow.
