---
name: forge
description: >
  Rigorous phased development workflow. Use when the user invokes /forge
  to start a high-accuracy development task requiring strict planning,
  execution discipline, documentation, and debugging rigor.
version: 1.0.0
user-invocable: true
argument-hint: <task description>
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Rigorous Development Workflow

All rules in this document are mandatory. No rule may be skipped, simplified, or approximated.

## Overriding Principle: Production-Grade Quality

This project targets commercial release. Every implementation decision must prioritize **performance and reliability**, not simplicity or convenience.

- **Do not default to "simplest correct."** The simplest approach is often naive — O(n²) when O(n) exists, polling when event-driven is available, copying when borrowing suffices, linear scan when an index is warranted.
- **Performance is a requirement, not an optimization.** Choose data structures, algorithms, and APIs with performance characteristics appropriate for production workloads. Justify choices with complexity analysis when non-trivial.
- **Reliability is non-negotiable.** Handle edge cases, resource exhaustion, concurrent access, and failure modes. Do not defer error handling to "later." Do not assume inputs are well-formed unless validated at the boundary.
- **Do not write throwaway code.** Every line committed should be maintainable, testable, and production-ready. Prototyping is acceptable only when explicitly labeled as such in the plan.

This principle takes precedence in all phases: planning (choose robust approaches), implementation (write production code), review (reject naive solutions), and debugging (fix properly, not minimally).

## Task

$ARGUMENTS

If no task description is provided above, ask the user to describe the task before proceeding.

---

## RULE 1: Self-Monitoring

This rule is enforced at two levels:

**Harness level (automatic):** The `PreToolUse` hook (`pre-tool-use-guard.sh`) injects a compact rules summary into the conversation context every 10 tool calls, and blocks execution if documentation is not being maintained. This operates independently of Claude's memory.

**Conversation level (manual checkpoints):** Before each phase transition (C.1 Pre-Phase), re-read the current active plan document to refresh objectives and expected results.

If at any point the workflow rules feel unclear or uncertain, re-read this file:
```
${CLAUDE_PLUGIN_ROOT}/skills/forge/SKILL.md
```

---

## RULE 2: Continuous Execution

- Do not pause between phases.
- Do not ask "shall I continue?", "should I proceed?", or equivalent.
- Do not explain what the next step will be — execute it directly.
- The only reasons execution may stop:
  1. The user interrupts via ESC/Ctrl+C or other Claude Code interrupt operations.
  2. The user explicitly requests a pause via text (e.g., "暂停", "pause", "stop").
  3. An unsolvable issue triggers a full re-plan (RULE 3, re-plan trigger).
- When the user requests a pause via text: mark the current plan `Status: PAUSED`, then stop. The `Stop` hook will detect the non-ACTIVE status and allow the stop.
- When committing code, invoke `/git-commit`.

---

## RULE 3: Phased Development

### Bootstrap

Before any planning, initialize the documentation structure:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/forge/scripts/init-docs.sh
```

### META-PHASE A: Planning

1. Analyze the task: read existing code, understand requirements, explore the codebase.
2. Identify alternative approaches. For each, document technical pros, cons, and rationale. Select the approach with the strongest technical justification.
3. Create a detailed plan divided into sequential phases. For each phase, specify:
   - Objective
   - Expected results: must be **precise and testable** — define what "implemented" means (compiles? passes tests? handles edge cases?). Distinguish between stub/placeholder and real implementation.
   - Dependencies on prior phases: **build a dependency graph** and verify no circular dependencies exist.
   - Risks and unknowns: for each phase, list what could go wrong and how to detect it early.
4. Write the plan to `docs/plan/<name>.md` using the template at `${CLAUDE_PLUGIN_ROOT}/skills/forge/templates/plan.md`. Set `Status: ACTIVE`.
5. Create the corresponding `docs/progress/<name>.md` using the progress template.
6. Log the planning action to the progress document.

### META-PHASE B: Plan Review

Re-read the entire plan document, then produce a **Review Checklist** in the progress document under `### Plan Review`. This checklist is mandatory — a review without it is not a review.

The checklist must address each item with a PASS/FAIL/RISK verdict and evidence:

1. **Dependency validation**: trace the dependency graph. For each "depends on Phase X", verify Phase X's outputs are sufficient inputs for this phase. Check for circular dependencies.
2. **Expected results precision**: for each phase's expected results, answer: "How exactly will I verify this?" If the answer is vague, the expected result must be rewritten.
3. **Feasibility assessment**: for each phase, is the expected result achievable given the current codebase state? Flag phases where the effort is uncertain or where hidden dependencies may exist.
4. **Risk identification**: what could cause each phase to fail? Are there external dependencies (OS APIs, third-party crates, hardware) that need investigation before execution?
5. **Stub vs real implementation**: explicitly mark which deliverables are stubs/placeholders and which are full implementations. The plan must not use ambiguous terms like "implemented" without qualification.
6. **Alternatives completeness**: were the rejected alternatives properly evaluated, or dismissed without evidence?

If any item is FAIL or RISK, fix the plan before proceeding. This is the draft stage — **direct edits to the plan are permitted**.

Log the completed checklist to progress. A one-line "review complete, no changes" is **never acceptable** — the checklist must have per-item entries.

### META-PHASE C: Phase Execution (loop over each phase)

#### C.1 Pre-Phase
- **Re-read the active plan document** — specifically this phase's objective, expected results, and dependencies. This is not optional. After re-reading, log to progress: `### Starting Phase N` with a brief restatement of expected results (proves the plan was re-read).
- If the plan was corrected since last read, verify the corrections are understood before proceeding.

#### C.2 Execute
- Implement the phase according to the plan.
- Follow existing code conventions and patterns.

#### C.3 Review

Produce a **Phase Review** entry in the progress document under `### Review: Phase N`. This entry is mandatory — a phase without a review entry cannot be marked COMPLETE. A PostToolUse hook will verify its presence.

The review MUST use this exact table format (one row per expected result from the plan):

```
### Review: Phase N

| # | Expected Result | Actual Result | Evidence | Verdict |
|---|-----------------|---------------|----------|---------|
| 1 | [copy from plan] | [what happened] | [file path / build output / test output] | PASS/FAIL/PARTIAL |
| 2 | ... | ... | ... | ... |

**Overall Verdict**: PASS / FAIL
**Notes**: [any observations, risks, or caveats]
```

Rules:
- The table must have one row for every expected result listed in the plan for this phase. Missing rows = incomplete review.
- Evidence must be concrete: file paths, command outputs, test results. "It works" is not evidence.
- PARTIAL counts as FAIL for the overall verdict.
- If any expected result was never executed at runtime, its verdict must be `PASS [UNVERIFIED]` with verification method noted.

If overall verdict is FAIL → enter C.4 which will route to RULE 5 (debugging).
If overall verdict is PASS → proceed to C.4 for functional acceptance.

#### C.4 Functional Acceptance (RULE 4)
- Execute the acceptance procedure defined in RULE 4.
- If PASS: log success, proceed to C.5.
- If FAIL: record issue in `docs/issue/`, enter debugging (RULE 5).

#### C.5 Post-Phase
- **Pre-condition**: verify that progress contains both `### Review: Phase N` (C.3) and a functional acceptance log (C.4) for this phase. If either is missing, go back and complete them. A phase CANNOT be marked COMPLETE without both artifacts.
- Mark the phase as COMPLETE in the plan document.
- Update progress with timestamp and results.
- Proceed to the next phase without pausing (RULE 2).

#### Plan Correction During Execution
If the plan is found to be incorrect or insufficient during execution:
- Do **not** overwrite the existing plan content.
- Mark the affected section as `[DEPRECATED]`.
- Add a new section or create a new plan file with the corrected approach.
- Cross-reference: `Correction-of: [plan/<name>#<section>]`, `Reason: <evidence-based rationale>`.
- Log the correction in `docs/progress/<name>.md` under "Plan Corrections".

#### Re-Plan Trigger
If an issue is deemed unsolvable after exhausting the escalation protocol (RULE 5, section 5e):
1. Mark the current plan `Status: DEPRECATED`, add `Superseded-by: [plan/<new-name>]`.
2. Create a new plan file referencing the deprecated plan and explaining what changed and why.
3. Restart from META-PHASE A with accumulated findings.

### META-PHASE D: Completion

1. Conduct a full review of all implemented phases.
2. Run final compilation/build verification.
3. Mark the plan `Status: COMPLETED`.
4. Write a summary entry in progress.
5. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/forge/scripts/check-doc-format.sh` to validate documentation.

---

## RULE 4: Functional Acceptance

After each phase implementation (META-PHASE C.4):

1. **Build**: Compile, build, lint, or type-check as appropriate for the project.
2. **Verify**: Compare actual outputs against the expected results documented in the plan for this phase. Be precise — partial matches are failures.
3. **Result**:
   - **PASS**: Log to progress with evidence (build output, test output). Continue to next phase.
   - **FAIL**: Record the deviation in `docs/issue/<name>.md` with status `IN-PROGRESS`. Enter RULE 5 (debugging).

---

## RULE 5: Debugging Discipline

### 5a. No Workarounds

- Do not comment out failing code to bypass errors.
- Do not use catch-and-ignore patterns to suppress exceptions.
- Do not apply temporary fixes or "good enough" solutions.
- Do not use stubs, `unreachable!()`, `unimplemented!()`, no-op implementations, or dummy return values as "fixes" — these are workarounds that mask the real problem. If a stub is genuinely needed (e.g., a dependency has no platform support), it must be explicitly planned as a stub in the plan document, not introduced during debugging as a fix.
- Every fix must address the root cause, not mask symptoms. If a fix makes the compiler happy but the functionality doesn't actually work, it is a workaround.

### 5b. Diagnose Before Fixing

Sequence: observe symptom → form hypothesis → gather evidence → confirm root cause → fix.

- The only exception: adding debug logging is permitted before diagnosis is complete.
- Do not guess at fixes. If a fix is attempted without confirmed root cause, it is a guess.

### 5c. Diagnostic Tools

Use all available tools as appropriate:
- Log output analysis (read carefully and completely)
- Targeted debug logging
- Debuggers: lldb, gdb
- Decompilation tools for binary analysis
- Memory inspection, stack traces, variable state examination
- Dependency source code reading
- Web search for documented issues or API behavior

### 5d. Fix Process (follows RULE 3 + RULE 4)

After root cause is confirmed:
1. Formulate a fix plan (record in the issue document, or append a fix phase to the plan).
2. Review the fix plan for correctness and completeness.
3. Implement the fix.
4. Review the implementation.
5. Functional acceptance: build passes + fix verified + regression check (no new issues introduced).

### 5e. Escalation Protocol

Track every distinct fix attempt in the issue document.

- **3 different failed fix attempts** for the same issue: stop, re-read the plan and all related issue entries. The current approach is fundamentally flawed — devise a different strategy, not a variation of the same one.
- **5 different failed plans** for the same issue: stop all implementation. Mark the issue `BLOCKED`. Write a detailed analysis. Re-evaluate the entire approach holistically — trigger a re-plan (META-PHASE A).
- **N similar issues** (same category of defect appearing repeatedly): stop and examine the broader scope. Do not continue fixing individual instances. Investigate:
  - Whether there is a systemic design or architectural flaw.
  - Whether the same class of deficiency exists in other locations (e.g., a class repeatedly missing methods should trigger a comprehensive audit of all required methods, not incremental additions per debug cycle).
  - Apply the fix systemically to all affected locations at once.

---

## RULE 6: Documentation

### Quality Requirements

- Use formal, precise technical language. Colloquial or vague descriptions are not acceptable.
- All technical conclusions must be based on verifiable sources: source code reading, compilation/execution output, official documentation, authoritative search results.
- Do not state hypotheses or assumptions as facts. Unverified content must be marked `[UNVERIFIED]` with the planned verification method. In particular: if a code path has never been executed at runtime, any claim that it "works" or "passes" must be marked `[UNVERIFIED]` — compilation alone does not verify correctness.
- Record the evidence source: source file paths, documentation URLs, command output excerpts.

### Document Types and Templates

Templates are located at `${CLAUDE_PLUGIN_ROOT}/skills/forge/templates/`.

- **Plan** (`docs/plan/<name>.md`): Task decomposition, alternatives analysis, phase definitions, expected results.
- **Progress** (`docs/progress/<name>.md`): Chronological execution log, plan corrections, discoveries.
- **Issue** (`docs/issue/<name>.md`): Defect tracking with diagnosis, fix attempts, and resolution.

### Naming Convention

- File names are concise and descriptive: `auth-login.md`, `ISS-003.md`, `core.md`.
- Progress documents share the same name as their corresponding plan.
- Issue documents are organized by module or category.

### Source Linkage

Every plan and progress document must declare its source in the header:
- Feature plan/progress → link to the task description or requirement source.
- Issue fix plan/progress → link to `issue/<name>.md#ISS-NNN`.

### Findings Mechanism

Every document (plan, progress, issue) contains a `## Findings` section.
- Each finding is a subsection: `### F-NNN: <title>`.
- Internal reference: `[F-NNN]`.
- Cross-document reference: `[plan/<name>#F-NNN]`, `[progress/<name>#F-NNN]`, `[issue/<name>#F-NNN]`.
- Unverified findings must include `[UNVERIFIED]` and a verification plan.

### Append-Only Rule (during execution)

- During META-PHASE B (review): direct edits to the plan are permitted.
- During META-PHASE C and beyond: all documents are append-only.
  - Do not overwrite or delete previous content.
  - Old plan sections are marked `[DEPRECATED]`, never removed.
  - Issue status changes are appended as new entries.
- All entries include timestamps.

### Cross-Reference Format

- `[plan/<name>#PhaseN]` — reference a plan phase
- `[progress/<name>#<timestamp>]` — reference a progress entry
- `[issue/<name>#ISS-NNN]` — reference a specific issue
- `[<doc-type>/<name>#F-NNN]` — reference a finding

### Document Splitting

When any document exceeds approximately 500 lines:
1. Create a new file with a sequence suffix: `<name>-02.md`.
2. Append to the end of the old file: `Continued in: <name>-02.md`.
3. Begin the new file with: `Continuation of: <name>.md`.

---

## RULE 7: Autonomous Task Planning

When all phases in the current plan are complete, or when no explicit next-step instruction is available:

1. **Assess current state**: scan all documents in `docs/`:
   - Completed phases and their results.
   - Issues with status `IN-PROGRESS` or `BLOCKED`.
   - Findings marked `[UNVERIFIED]`.
   - Any dependencies that have been unblocked.

2. **Prioritize**: rank potential next tasks by:
   - Blocking severity: tasks that unblock other work take precedence.
   - Impact scope: issues affecting multiple components over isolated ones.
   - Urgency: `BLOCKED` issues that now have a viable path forward.
   - Verification debt: accumulated `[UNVERIFIED]` findings.

3. **Plan and execute**: create a new plan document for the selected task (following META-PHASE A → B flow) and continue execution (RULE 2).

4. **Stop hook integration**: when a plan is marked `COMPLETED`, the `Stop` hook outputs non-blocking reminders about unresolved issues and unverified findings. Use these reminders to inform the next task selection.

---

## Execution Summary

```
1. Bootstrap: run init-docs.sh
2. META-PHASE A: create plan with phases and expected results
3. META-PHASE B: review and refine plan (direct edits allowed)
4. META-PHASE C: for each phase:
   a. Pre-Phase: re-read plan
   b. Execute
   c. Review implementation
   d. Functional acceptance (RULE 4)
   e. If FAIL: debug (RULE 5, which also follows RULE 3+4 for fixes)
   f. If PASS: mark complete, update progress, next phase
5. META-PHASE D: final review, mark plan COMPLETED
6. RULE 7: assess state, plan next task, continue
```

Begin now.
