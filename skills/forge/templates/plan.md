# Plan: {{PLAN_NAME}}

Created: {{TIMESTAMP}}
Status: ACTIVE
Source: {{SOURCE_REFERENCE}}

<!--
  This plan document tracks the complete planning lifecycle for a task.
  - Status values: ACTIVE | COMPLETED | PAUSED | DEPRECATED
  - When deprecating: add "Superseded-by: [plan/<new-name>]" and change Status to DEPRECATED
  - During META-PHASE B (review): direct edits are permitted
  - During META-PHASE C+ (execution): append-only; mark modified sections [DEPRECATED] and add new sections
-->

## Task Description

{{TASK_DESCRIPTION}}

## Alternatives & Trade-offs

<!--
  Document all approaches considered, with technical rationale for selection/rejection.
  All claims must be verifiable (source code, documentation, test results).
-->

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|

## Feasibility Research

<!--
  A.3 Feasibility Research (mandatory before writing phases).
  Enumerate technical assumptions the chosen approach depends on, then verify each
  with a runtime/source-level action. Record exact evidence.

  Any REJECTED or INCONCLUSIVE assumption blocks the plan — return to Alternatives.
  Only when all assumptions are CONFIRMED may Phases be written below.

  For high-risk assumptions, include a minimal POC: file path, run command, and output.
-->

| # | Assumption | Verification Action | Evidence (actual output) | Status |
|---|------------|---------------------|--------------------------|--------|
| A1 | [specific technical claim] | [exact command / source read / POC script / doc URL] | [actual command output or excerpt] | CONFIRMED/REJECTED/INCONCLUSIVE |

## Phases

### Phase 1: {{PHASE_1_NAME}}

**Objective**: {{OBJECTIVE}}

**Expected Results**:
- [ ] {{VERIFIABLE_RESULT_1}}
- [ ] {{VERIFIABLE_RESULT_2}}

**Dependencies**: None

**Status**: PENDING

<!-- Repeat for additional phases -->

## Findings

<!--
  Each finding is a subsection: ### F-NNN: <title>
  Reference within this document: [F-NNN]
  Reference from other documents: [plan/<name>#F-NNN]
  Unverified findings must be marked [UNVERIFIED] with planned verification method.
-->
