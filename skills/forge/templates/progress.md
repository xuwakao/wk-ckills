# Progress: {{PROGRESS_NAME}}

Created: {{TIMESTAMP}}
Source: {{SOURCE_REFERENCE}}

<!--
  This progress document records the chronological execution log.
  - Entries are append-only with timestamps.
  - Cross-reference plans: [plan/<name>#PhaseN]
  - Cross-reference issues: [issue/<name>#ISS-NNN]
  - Record plan corrections with rationale and link back to the plan document.
-->

## Log

<!--
  Format per entry:
  ### [TIMESTAMP] Phase N - Action Title
  **Action**: What was done
  **Result**: Outcome (PASS/FAIL/PARTIAL)
  **Cross-ref**: Related plan/issue references
  **Notes**: Additional observations
-->

## Plan Corrections

<!--
  Record any corrections made to the plan during execution.
  Format:
  ### [TIMESTAMP] Correction: <summary>
  **Original**: [plan/<name>#section]
  **Reason**: Why the correction is necessary (with evidence)
  **New plan**: [plan/<name>#section] or new plan file reference
-->

## Findings

<!--
  Each finding is a subsection: ### F-NNN: <title>
  Reference within this document: [F-NNN]
  Reference from other documents: [progress/<name>#F-NNN]
  Unverified findings must be marked [待验证].
-->
