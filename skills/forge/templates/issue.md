# Issues: {{ISSUE_CATEGORY}}

Created: {{TIMESTAMP}}

<!--
  This issue document tracks bugs, defects, and problems encountered during development.
  - Each issue has a unique ID within this file: ISS-001, ISS-002, ...
  - Status values: IN-PROGRESS | RESOLVED | NOT-NEEDED | BLOCKED
  - Status updates are appended, not overwritten.
  - Cross-reference plans: [plan/<name>#PhaseN]
  - Cross-reference progress: [progress/<name>#<timestamp>]
  - Every fix attempt must be recorded with its result.
-->

## Issue Index

| ID | Status | Summary | Root Cause | Plan-ref | Progress-ref |
|----|--------|---------|------------|----------|--------------|

## Issues

<!--
  Format per issue:

  ### ISS-NNN: <summary>

  **Status**: IN-PROGRESS
  **Reported**: [timestamp]
  **Phase**: [plan/<name>#PhaseN]
  **Symptom**: Precise description of observed behavior
  **Expected**: What should have happened

  #### Diagnosis · Investigation (Stage 1 — runs BEFORE hypotheses)

  **Failing code path**:
  - Grep: `<command>` → [output]
  - Read: [file:lines]

  **Runtime behavior** (debugger / logs / trace / instrumentation):
  - [tool]: [command] → [exact output]
  - [tool]: [command] → [exact output]

  **Related code / dependencies / history**:
  - Read: [file:lines] — [what it does]
  - `git log -p` / `git blame`: [findings]

  #### Diagnosis (Stage 2 — hypotheses informed by investigation)

  **Symptom (precise)**: [exact error message + reproduction steps]

  **Investigation summary**: [one line referencing what the actual code/runtime revealed]

  **Hypotheses** (minimum 2 — grounded in the investigation above):

  | # | Hypothesis | Verification Method (runtime, not code-reading) | Verification Result | Status |
  |---|------------|------------------------------------------------|---------------------|--------|
  | H1 | [specific cause, informed by investigation] | [lldb command / log grep / trace filter / reproduction run] | [exact output] | CONFIRMED/REJECTED/INCONCLUSIVE |
  | H2 | [alternative cause] | ... | ... | ... |

  **Root Cause**: [must reference the H# marked CONFIRMED, with runtime verification evidence. If no hypothesis CONFIRMED after 2 investigation iterations → mark issue BLOCKED and stop.]

  #### Fix Attempts
  1. [timestamp] **Attempt**: Description of fix
     **Result**: PASS/FAIL
     **Analysis**: Why it worked or failed

  #### Resolution
  **Fix**: Final resolution description
  **Verification**: How correctness was verified (compilation, test, manual check)
  **Regression**: Confirmation that no new issues were introduced
  **Resolved**: [timestamp]
  **Status**: RESOLVED
-->

## Findings

<!--
  Each finding is a subsection: ### F-NNN: <title>
  Reference within this document: [F-NNN]
  Reference from other documents: [issue/<name>#F-NNN]
  Unverified findings must be marked [UNVERIFIED].
-->
