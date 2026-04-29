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

## Requirements

<!-- A.0 — Requirements Analysis.
     If ambiguous, STOP and ask user via Open Questions. Do NOT guess intent. -->

### User Stories / Intent

<!-- "As <user>, I want <capability>, so that <benefit>."
     Or technical form: "The system must <capability> because <reason>." -->

### Acceptance Criteria (business-level, testable)

| ID | Criterion | How to verify (at delivery time) |
|----|-----------|---------------------------------|
| AC-1 | [user-observable behavior] | [how an outsider would verify] |

### Non-Functional Requirements (NFR)

<!-- Include only what applies -->
- **Performance**:
- **Security**:
- **Compatibility**:
- **Reliability**:
- **Compliance**:

### Open Questions for the User

<!-- List anything ambiguous. STOP and wait for user before proceeding to A.1. -->

## Codebase Reconnaissance

<!-- A.1 — Prove that codebase reading actually happened. Every entry references
     a real Grep/Read/Glob/Bash action. -->

### Search actions

| # | Action | Tool / Command | Outcome |
|---|--------|----------------|---------|
| S1 | [what was searched for] | [exact command] | [what was found] |

### Files read (with what each contributed)

- `path/to/file:Lstart-Lend` — [what was learned]

### Existing patterns identified (reusable)

- **Pattern 1**: [pattern + reference]

### Similar features already in the codebase (use as reference)

- [feature path] — [why relevant]

### Constraints discovered

- C-1: [constraint + cite]

## Architecture Decision

<!-- A.2 — Formal Architecture Decision Record (ADR). -->

**ADR ID**: ADR-NNN
**Title**: [concise decision statement]
**Status**: PROPOSED
**Date**: {{TIMESTAMP}}
**Context**: [problem, constraints, link to AC-N/NFRs]

### Prior Art Survey

<!-- A.2 Stage 0 — Mandatory before listing alternatives. Each row needs a real
     Grep/Read/WebSearch/WebFetch action. -->

| # | Source | Search action | Findings |
|---|--------|--------------|----------|
| P1 | This codebase | [Grep/Read command] | [what was found] |
| P2 | Direct dependency | [command or doc URL] | [what was found] |
| P3 | Comparable projects | [WebSearch query] | [findings + names] |
| P4 | Authoritative spec | [WebFetch URL] | [relevant section] |
| P5 | Known pitfalls | [WebSearch query] | [anti-patterns surfaced] |

### Alternatives Considered

| # | Approach | Pros | Cons | Verdict | Rationale |
|---|----------|------|------|---------|-----------|
| 1 | [chosen] | ... | ... | SELECTED | [why, evidence-based] |
| 2 | [alt] | ... | ... | REJECTED | [specific reason with evidence] |

### Decision

**Chosen approach**: [approach name]

**Why**: [2-4 sentence technical argument]

**Key assumptions** (verified in Feasibility Research below as A1, A2, …):
- ...

### Consequences

- **Positive**:
- **Negative**:
- **Neutral / notable**:

### Supersedes

<!-- Optional: "Supersedes ADR-MMM because ..." -->

## Feasibility Research

<!-- A.3 — Mandatory before writing phases. Any REJECTED/INCONCLUSIVE blocks the plan. -->

| # | Assumption | Verification Action | Evidence (actual output) | Status |
|---|------------|---------------------|--------------------------|--------|
| A1 | [specific technical claim] | [exact command / source read / POC script / doc URL] | [actual command output or excerpt] | CONFIRMED/REJECTED/INCONCLUSIVE |

<!-- When all CONFIRMED, update Architecture Decision status from PROPOSED to ACCEPTED. -->

## Phases

### Phase 1: {{PHASE_1_NAME}}

**Objective**: {{OBJECTIVE}}

**AC coverage**: AC-1, AC-2  <!-- which Acceptance Criteria this phase contributes to -->

**Expected Results**:
- [ ] {{VERIFIABLE_RESULT_1}}
- [ ] {{VERIFIABLE_RESULT_2}}

**Dependencies**: None

**Risks**: (each risk cross-references [A#] from Feasibility Research, or notes "no A# — discovered here")

**Related ADRs**: [ADR-NNN]

**Status**: PENDING

#### Phase 1: Test Plan

<!-- A.5 — Designed by independent QA subagent from AC+NFR, BEFORE implementation.
     Do NOT look at code to write tests. -->

**Traces to AC**: AC-1, AC-2

| ID | Level | Test Case | Input / Setup | Expected Output / Behavior | Traces to AC |
|----|-------|-----------|---------------|---------------------------|--------------|
| T1 | unit | ... | ... | ... | AC-1 |
| T2 | integration | ... | ... | ... | AC-1, AC-2 |
| T3 | e2e | ... | ... | ... | AC-2 |

<!-- Repeat for additional phases -->

## Findings

<!--
  Structured findings (not bare titles).
  Type: DECISION | DISCOVERY | CONSTRAINT | WARNING | BENCHMARK | GAP
  Status: ACTIVE | SUPERSEDED | OBSOLETE | [UNVERIFIED]
  Include: Tags, Context, Statement, Evidence, Impact/So what, Related.
-->

### F-001: [concise title]

**Type**: DISCOVERY
**Status**: ACTIVE
**Date**: {{TIMESTAMP}}
**Tags**: [space-separated, e.g., `platform:macos layer:net perf`]
**Context**: [which phase/issue/investigation]

**Statement**: [one paragraph precise statement]

**Evidence**: [file paths w/ line numbers, command outputs, URLs, POC refs]

**Impact / So what**: [who/what affected; what future decisions it constrains]

**Related**: [optional cross-refs to F-NNN, ADR-NNN, issue/file#ISS-NNN]
