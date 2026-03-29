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
  Unverified findings must be marked [待验证] with planned verification method.
-->
