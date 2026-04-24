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

## Mandatory Status Banner

Every response you produce while the /forge workflow is active MUST begin with this banner as the very first line(s):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[/forge] plan=<name> · phase=<N>/<total> · meta=<state> · issues=<open> · findings=<count>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Field definitions

- `plan` = filename of the currently active plan in `docs/plan/` (without `.md`). If multiple plans are ACTIVE, use the most recently modified one.
- `phase` = current phase number / total phase count, parsed from the plan's `### Phase N:` headers.
- `meta` = exactly one of: `A` (planning), `B` (plan-review), `C.1` (pre-phase), `C.2` (execute), `C.3` (review), `C.3-fix` (iterating fixes during multi-round review), `C.4` (acceptance), `C.5` (post-phase), `D` (completion), `RULE5` (debugging), `RULE7` (autonomous planning).
- `issues` = count of issues with status `IN-PROGRESS` or `BLOCKED` across all files in `docs/issue/`.
- `findings` = total count of `### F-NNN:` headers across all files in `docs/`.

### How to obtain field values

Field values **must be obtained from actual file reads**, not from memory or estimation. If you have not read these files in the recent context, run a quick verification before responding:

```bash
# Get all values in one shot
ls docs/plan/ 2>/dev/null
grep -c '### F-' docs/**/*.md 2>/dev/null || echo 0
grep -rE '(IN-PROGRESS|BLOCKED)' docs/issue/ 2>/dev/null | wc -l
```

Inventing or estimating field values is a violation. A banner with fabricated numbers is worse than no banner — it gives a false signal of compliance.

### When `?` is permitted

You may use `?` for a field **only** when the underlying data physically does not exist:
- `plan=?` — only if `docs/plan/` is empty (no plan created yet, e.g., during META-PHASE A before writing the plan)
- `phase=?` — only if no phases have been written yet
- `issues=?` — never; if `docs/issue/` is empty, the value is `0`, not `?`
- `findings=?` — never; if there are no findings, the value is `0`, not `?`
- `meta` — never; you always know which meta-phase you are in

Filling `?` to skip the work of reading files is a violation.

### Banner enforcement

The banner is a **proof-of-life signal**. Its presence tells the user: "I have just read the plan/issue/findings files and I know exactly where I am in the workflow." Its absence tells the user: "I have forgotten the workflow."

The banner is required:
- In every response while `.forge-counter` exists in the project
- Including short replies, error messages, and tool result summaries
- Including responses that only contain tool calls — the banner goes before the first tool call's narration text

The banner is NOT required:
- When `.forge-counter` does not exist (forge is not active in this project)
- When the active plan's status is `PAUSED`, `COMPLETED`, or `DEPRECATED`

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

**A.1 — Task analysis.** Read existing code, understand requirements, explore the codebase.

**A.2 — Approach identification.** Identify alternative approaches. For each, document technical pros, cons, and rationale. Tentatively select the approach with the strongest technical justification, pending feasibility verification in A.3.

**A.3 — Feasibility Research (mandatory before writing phases).**

Every approach rests on technical assumptions ("library X supports feature Y", "API Z works on platform W", "this syscall is available", "the dependency has this function", "the method scales to N items"). Unverified assumptions are the #1 cause of plans that turn out to be infeasible mid-execution.

This step verifies those assumptions **before** committing to the approach. It is a two-stage process modeled on C.3b Code Review and RULE 5b Diagnosis:

###### Stage 1 — Assumption Enumeration

List every technical assumption the chosen approach depends on. Be explicit — for each:
- Capability: "Library X supports feature Y"
- Behavior: "API Z returns X on input Y"
- Availability: "Syscall/crate/module W is available on target platform"
- Performance: "Approach scales to N items in under T time"
- Compatibility: "Version A is compatible with version B"

Typically 3–10 assumptions per non-trivial approach. If you cannot identify any assumptions, you have not understood the approach — go back to A.1.

###### Stage 2 — Verification Table

Produce a **Feasibility Research** section in the plan document under `## Feasibility Research`.

For each assumption, define a concrete verification action and execute it. Record the actual output in the "Evidence" cell.

```
## Feasibility Research

| # | Assumption | Verification Action | Evidence (actual output) | Status |
|---|------------|---------------------|--------------------------|--------|
| A1 | [specific technical claim] | [exact command / file read / POC script / doc URL — the action that will prove or disprove this] | [actual command output, file excerpt, link] | CONFIRMED / REJECTED / INCONCLUSIVE |
| A2 | ... | ... | ... | ... |
```

Verification action requirements:

- **Must be runtime / source-level**, not assumption-level. Acceptable examples:
  - `cargo tree -p <crate> -f '{p} {f}'` → confirmed output
  - `grep -rn 'fn <name>' <dep-source-path>` → confirmed the function exists with signature X
  - `man <syscall>` → confirmed available on target platform
  - `curl <api>` → confirmed response shape
  - 10-line proof-of-concept script executed → confirmed behavior
  - Read `<vendor-source>/src/<file.rs>:L42-80` → confirmed mechanism
- **Not acceptable** (these are assertions, not verifications):
  - "Checked the docs" (which docs? what did they say?)
  - "Should work based on the README"
  - "This is a common pattern, so it works"
  - "The library name suggests it does X"

Status rules:
- **CONFIRMED**: evidence directly shows the assumption holds. Proceed.
- **REJECTED**: evidence shows the assumption is false. The approach based on this assumption is infeasible — return to A.2, pick a different approach or redesign.
- **INCONCLUSIVE**: verification attempted but not conclusive. Must be resolved before proceeding: either design a better verification, or treat the assumption as REJECTED.

###### Verification intensity

For low-risk assumptions (widely used APIs, well-documented behavior): a single command output or doc URL is sufficient.

For high-risk assumptions (new API, cross-platform claim, performance requirement, novel integration): write a **minimal proof-of-concept** — 10–50 lines of throwaway code that exercises the exact capability end-to-end. Record the POC file path, the command to run it, and the actual output. A POC that compiles but has never been run is not verification.

###### Gate

- **Any REJECTED assumption blocks the plan.** Return to A.2.
- **Any INCONCLUSIVE assumption blocks the plan.** Do more investigation until it becomes CONFIRMED or REJECTED.
- **Only when all assumptions are CONFIRMED** may you proceed to A.4 (writing phases).

**A.4 — Write phase definitions.** Now that the approach is feasibility-verified, create a detailed plan divided into sequential phases. For each phase, specify:
- Objective
- Expected results: must be **precise and testable** — define what "implemented" means (compiles? passes tests? handles edge cases?). Distinguish between stub/placeholder and real implementation.
- Dependencies on prior phases: **build a dependency graph** and verify no circular dependencies exist.
- Risks and unknowns: for each phase, list what could go wrong and how to detect it early. Each risk should cross-reference the Feasibility Research assumption it relates to, or note "no A# — risk discovered here".

**A.5 — Write the plan** to `docs/plan/<name>.md` using the template at `${CLAUDE_PLUGIN_ROOT}/skills/forge/templates/plan.md`. Set `Status: ACTIVE`. The plan document must contain both the Feasibility Research table (from A.3) and the phase definitions (from A.4).

**A.6 — Create the corresponding `docs/progress/<name>.md`** using the progress template. Log the planning action (including feasibility verification summary) to the progress document.

### META-PHASE B: Plan Review

Re-read the entire plan document. Produce a **Plan Review** entry in the progress document under `### Plan Review`. This is a structured, multi-round review — not a formality.

**The review MUST use this exact table format** (one row per phase):

```
### Plan Review

| Phase | Dependencies OK | Expected Results Testable | Feasibility | Risks Identified | Stub/Real Marked | Verdict |
|-------|----------------|--------------------------|-------------|-----------------|-----------------|---------|
| 1     | [trace: no deps] | [how to verify each result] | [evidence] | [list risks] | [which are stubs] | PASS/FAIL/RISK |
| 2     | [Phase 1 outputs X, Phase 2 needs X → OK / CIRCULAR] | ... | ... | ... | ... | ... |
```

Each cell must contain **specific evidence**, not assertions. Examples of what is NOT acceptable vs acceptable:

| Column | NOT acceptable | Acceptable |
|--------|---------------|------------|
| Dependencies OK | "yes" | "Phase 2 needs compiled libfoo.a from Phase 1 output → verified Phase 1 produces it" |
| Expected Results Testable | "yes, can test" | "Verify via: `cargo test --lib hvf` must pass 3 tests; `cargo build` exit 0" |
| Feasibility | "should be fine" or any text not referencing A# | "[A3 CONFIRMED] kqueue API available, `man kqueue` returned on macOS 14" or "[A7 CONFIRMED + POC] 30-line POC at /tmp/poc.rs exec success" |
| Risks | "none" | "Risk: cros_async has no macOS backend [A5 CONFIRMED via `cargo tree -p cros_async -f '{p} {f}'`]" |

**Feasibility column must reference the Feasibility Research assumptions (A1, A2, ...) from META-PHASE A.3.** A Feasibility cell that does not cite an A# means the feasibility was not actually verified — treat as FAIL.

**Additional cross-cutting checks** (separate section after the table):

1. **Dependency graph**: draw the actual dependency order. Verify no cycles. Format: `Phase 1 → Phase 2 → Phase 3; Phase 1 → Phase 4`. If a cycle exists, it must be resolved before proceeding.
2. **Alternatives completeness**: for each rejected alternative in the plan, verify it has evidence-based rationale. Flag any that were dismissed without investigation.

**Plan Review is iterative:**
1. If any phase has verdict FAIL or RISK → fix the plan (direct edits permitted in META-PHASE B).
2. Re-run the review: produce `### Plan Review (round M)` with a fresh table.
3. Repeat until all phases are PASS.

A one-line "review complete, no changes" is **never acceptable**. The table and dependency graph are mandatory artifacts.

### META-PHASE C: Phase Execution (loop over each phase)

#### C.1 Pre-Phase
- **Re-read the active plan document** — specifically this phase's objective, expected results, and dependencies. This is not optional. After re-reading, log to progress: `### Starting Phase N` with a brief restatement of expected results (proves the plan was re-read).
- If the plan was corrected since last read, verify the corrections are understood before proceeding.

#### C.2 Execute
- Implement the phase according to the plan.
- Follow existing code conventions and patterns.
- **During implementation, actively record findings** to the Findings section of the relevant document (plan, progress, or issue). A finding is any non-obvious information discovered during work that would be valuable for future reference. Examples:
  - API behavior that differs from documentation
  - Undocumented constraints or limitations of a dependency
  - Performance characteristics observed during testing
  - Architectural decisions forced by the codebase (and why)
  - Platform-specific quirks or incompatibilities
  - Alternative approaches considered and rejected during implementation (with reason)
- Record findings as they occur, not after the fact. Each finding: `### F-NNN: <title>` in the Findings section, referenced inline where relevant.

#### C.3 Review (two parts: outcome + code)

C.3 has two mandatory parts. **Both must be completed.** A phase without both review artifacts cannot be marked COMPLETE.

##### C.3a — Outcome Review

Produce a **Phase Outcome Review** entry in the progress document under `### Review: Phase N — Outcome`.

The review MUST use this exact table format (one row per expected result from the plan):

```
### Review: Phase N — Outcome

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

##### C.3b — Code Review

A passing outcome review (C.3a) does NOT mean the code is acceptable. Code can satisfy expected results yet contain hidden bugs, edge case failures, performance problems, workarounds, or quality issues.

**C.3b is a two-stage process: investigate first, then report.** The review table comes LAST, not first. Writing the table without doing the investigation is a violation — the evidence cells will be fabricated.

###### Stage 1 — Investigation (must be completed before Stage 2)

Produce an **Investigation Log** in the progress document under `### Review: Phase N — Code · Investigation`. The log records every concrete action taken to examine the code. Each entry must reference a real tool call made BEFORE writing this section.

Required investigation actions per modified file:

1. **Enumerate changes** (once per review round):
   - Tool call: `git diff --name-only HEAD~<N>..HEAD` or `git status`
   - Record: exact command output listing changed files

2. **Read the file** (or diff hunks for files >500 lines):
   - Tool call: `Read` on each file in full, or `Bash: git diff <ref> -- <file>` for diff-only review
   - Record: file path + total lines read + line ranges if partial

3. **Anti-pattern scan** (specific greps, not eyeballing):
   - Tool call: `Grep -n -E 'unwrap\(\)|\.expect\(|unimplemented!|todo!|panic!\(|# TODO|// TODO' <file>`
   - Record: exact output (matches or "no matches")

4. **Error path scan**:
   - Tool call: `Grep -n -E 'catch|rescue|except|if err|\?' <file>` (adjust regex per language)
   - Record: exact output; for each match, note whether it propagates/logs/ignores

5. **Complexity probes** (for non-trivial code):
   - Tool call: `Grep -n -E 'for.*in|while|loop' <file>` to locate loops, then read each loop's context
   - Record: identified hot paths and their complexity (traced, not guessed)

6. **Edge-case execution** (when tests exist):
   - Tool call: run the test command (e.g., `cargo test --lib <name> -- --nocapture`, `pytest -v -k <name>`)
   - Record: exact test output

Format the Investigation Log as:

```
### Review: Phase N — Code · Investigation

#### Changed files
Command: `git diff --name-only ...`
Output:
  path/a.rs
  path/b.rs

#### path/a.rs
- Read: full file, 243 lines
- Anti-pattern scan: `Grep -n -E '...' path/a.rs` → no matches
- Error path scan: 4 matches at lines 17, 52, 89, 134; propagation traced (see notes)
- Loops: 1 loop at line 102–118, complexity O(n) where n = input vec size
- Tests: `cargo test --lib foo` → 3 passed, 0 failed (output: ...)

#### path/b.rs
...
```

The Investigation Log must be written BEFORE Stage 2 and reference actual tool call outputs. If an action was not performed, the corresponding entry must say "NOT PERFORMED — reason: ..." rather than being omitted or faked.

###### Stage 2 — Report Table

Only after the Investigation Log is complete, produce the **Phase Code Review** entry under `### Review: Phase N — Code`.

Every evidence cell must reference a specific entry from the Investigation Log. Format: `[investigation: <file-section> · <action>]` followed by the observation.

```
### Review: Phase N — Code

| File | Logic | Edge Cases | Error Handling | Performance | Production Quality | Workarounds | Style | Verdict |
|------|-------|------------|----------------|-------------|-------------------|-------------|-------|---------|
| path/a.rs | [investigation: a.rs · Read] traced fn foo: branches at L17 handle empty vec; L52 handles >MAX | [investigation: a.rs · tests] boundary test for empty input passed at L103 of test output | [investigation: a.rs · error scan] all 4 error sites propagate via `?` | [investigation: a.rs · loops] O(n) single-pass, no nested loops, no allocations in loop body | naming consistent with sibling mod, no magic numbers | [investigation: a.rs · anti-pattern scan] 0 matches | consistent with surrounding modules (verified by reading 2 sibling files) | PASS |

**Files reviewed**: N
**Overall Verdict**: PASS / FAIL
```

Column criteria (each cell MUST reference the investigation and contain a specific observation):

- **Logic**: trace through the function using the code read in Stage 1. Cite specific branches/lines. "Looks correct" is not acceptable.
- **Edge Cases**: cite the specific boundary conditions examined and their behavior. If tests exist, cite test outputs; if not, cite the code path for each boundary.
- **Error Handling**: cite the error scan results. State whether each error path propagates, logs, or is ignored. No silent catches.
- **Performance**: cite the complexity probe. State complexity (O-notation) with the specific loop/recursion that determines it. Allocations, locks, copies identified by reading the code.
- **Production Quality**: maintainability concerns, naming, missing documentation on non-obvious logic. Cite specific lines.
- **Workarounds**: cite the anti-pattern scan output. Zero matches or justified matches (planned stubs with cross-reference) are acceptable.
- **Style**: cite sibling files/modules examined to verify consistency.

**Cells without investigation references are invalid.** A cell saying "logic is correct" without `[investigation: ...]` means the investigation was skipped — treat as FAIL.

Verdict per file:
- **PASS**: every column has a concrete observation backed by the investigation, and no concerns were found.
- **CONCERN**: issues identified by the investigation that should be addressed but are not blockers (note them in a finding).
- **FAIL**: investigation revealed issues that violate Overriding Principle, RULE 5a, or bugs not covered by the outcome review.

A file marked CONCERN is acceptable only if a finding is recorded explaining the deferred work and a plan to address it. FAIL must be fixed before moving on.

##### Findings audit

As part of C.3 (after both reviews), check whether any findings were recorded during C.2. If the Findings section is empty for this phase, ask: "Was nothing non-obvious discovered during implementation?" If genuinely nothing — acceptable but unusual for complex phases. If findings exist but were not recorded — record them now. The review entry should note the findings count: `**Findings this phase**: N (see [F-NNN], [F-NNN]...)` or `**Findings this phase**: 0 (no non-obvious discoveries)`.

##### C.3 is iterative — unlimited rounds

C.3a and C.3b are not one-shot. **Every code change triggers a fresh review.** There is no maximum number of rounds.

If any FAIL or CONCERN is found in either C.3a or C.3b:

1. **Record each issue** in `docs/issue/<name>.md` with a new issue entry (ISS-NNN), status `IN-PROGRESS`, cross-referenced to `[plan/<name>#PhaseN]` and the specific file/line for code issues.
2. Fix the issue (following RULE 5 if it is a bug, or direct code correction if it is a quality issue).
3. Mark the issue as `RESOLVED` in the issue document with resolution details.
4. Re-run **both** C.3a and C.3b — produce new review entries `### Review: Phase N — Outcome (round M)` and `### Review: Phase N — Code (round M)`. Increment M with each round.
5. Repeat steps 1–4 until both reviews have Overall Verdict PASS with **zero FAIL and zero CONCERN** items.

The loop terminates only on a clean review, never on round count. If you find yourself in many rounds (5+), that is a signal to apply RULE 5e (escalation) — the implementation approach may need to change.

Only when both C.3a and C.3b are clean (PASS, no FAIL, no CONCERN) → proceed to C.4.

#### C.4 Functional Acceptance (RULE 4)
- Execute the acceptance procedure defined in RULE 4.
- If PASS: log success, proceed to C.5.
- If FAIL: record issue in `docs/issue/`, fix, then re-run C.3 Review (iterative loop).

#### C.5 Post-Phase
- **Pre-condition**: verify that progress contains ALL of the following for this phase:
  1. `### Review: Phase N — Outcome` (C.3a, final round with PASS verdict)
  2. `### Review: Phase N — Code` (C.3b, final round with PASS verdict)
  3. A functional acceptance log (C.4)

  If any of these are missing, go back and complete them. A phase CANNOT be marked COMPLETE without all three artifacts.
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
6. **Immediately proceed to RULE 7** — do NOT stop here. META-PHASE D completion is not the end of the workflow. RULE 7 determines the next task.

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

Diagnosis is a two-stage process: **investigate the real code first, then generate and verify hypotheses**. Skipping straight to hypotheses from the symptom alone is guessing, not diagnosis.

###### Stage 1 — Code & Runtime Investigation (before hypotheses)

Before proposing any hypothesis, investigate the actual system. Record every action in an **Investigation Log** in the issue document under `#### Diagnosis · Investigation`.

Required actions (perform the ones applicable to the bug):

1. **Locate the failing code path**:
   - Tool call: `Grep` for the exact error message / symptom string across the codebase
   - Tool call: `Read` every file along the call chain leading to the failure
   - Record: exact file paths and line numbers of the suspect code

2. **Examine runtime behavior with debugging tools** (not just reading):
   - **Logs**: read the actual error logs/stdout/stderr. Grep for surrounding context. Record: exact log excerpts.
   - **Debugger (lldb/gdb/equivalent)**: set breakpoints at the failing code, inspect variable state at the failure point. Record: exact backtrace + variable values.
   - **Tracing (strace/dtrace/truss)**: when the failure involves syscalls, I/O, or system boundaries. Record: relevant syscall outputs.
   - **Instrumentation**: add targeted debug prints/logs that capture the exact values/state at the decision points. Record: output of the instrumented run.
   - **Reproduction**: construct a minimal reproduction command and confirm the symptom reproduces. Record: exact command + output.

3. **Examine the related code layer(s)**:
   - Tool call: `Read` upstream callers and downstream callees
   - Tool call: `Read` the actual dependency/library source (not documentation — source) for any external calls involved
   - Tool call: `git log -p <file>` or `git blame <file>` for recent changes in the failing area
   - Record: what each layer does and where the state deviates from expectation

The Investigation Log must contain the exact tool outputs, not summaries. A log that says "examined the code" without citations means no investigation was done.

###### Stage 2 — Structured Hypothesis Verification

Only after Stage 1 is complete, generate hypotheses **informed by the investigation**. Write a `#### Diagnosis` section with this format:

```
#### Diagnosis

**Symptom (precise)**: [exact error message, observed behavior, and reproduction steps]

**Investigation summary**: [one line referencing the Investigation Log above — what did the actual code/runtime reveal?]

**Hypotheses**:
| # | Hypothesis | Verification Method | Verification Result | Status |
|---|------------|---------------------|---------------------|--------|
| H1 | [specific cause, informed by investigation] | [actual tool-level verification: lldb command, log grep, trace filter, reproduction step — NOT "read the code"] | [exact output of running the verification] | CONFIRMED / REJECTED / INCONCLUSIVE |
| H2 | [alternative cause] | ... | ... | ... |

**Root Cause**: [must reference the H# that was CONFIRMED, with the verification evidence]
```

Mandatory rules:

1. **Minimum 2 hypotheses.** Force alternatives across different layers (application/library/OS), different components, different timing.
2. **Hypotheses must be grounded in the investigation.** If a hypothesis does not cite the Investigation Log, it is a guess — reject it.
3. **Verification methods must be runtime-level, not code-reading.** Running the code with instrumentation, attaching a debugger, grepping real logs, or executing a reproduction — these are verifications. "Read the function again" is not; the code was already read in Stage 1.
4. **Run the verification before declaring status.** CONFIRMED requires runtime evidence. REJECTED requires runtime evidence the hypothesis is wrong. INCONCLUSIVE means the verification was attempted but did not resolve — must be followed by a different runtime verification or a new hypothesis.
5. **Root cause requires CONFIRMED status.** A hypothesis with INCONCLUSIVE or no verification cannot be root cause. If all hypotheses are REJECTED or INCONCLUSIVE, return to Stage 1 and deepen the investigation, then generate new hypotheses.
6. **No fixes before CONFIRMED root cause.** The only exception: adding debug instrumentation to enable verification is permitted.

**Stop condition — when no root cause can be verified:**

If after two iterations of (Stage 1 → Stage 2) you cannot arrive at a CONFIRMED root cause:
- STOP attempting fixes.
- Mark the issue `BLOCKED` with status update noting the attempted investigations and what was inconclusive.
- Report to the user. Do not proceed to fix without a verified root cause. A fix without a root cause is a guess.

**Anti-patterns explicitly forbidden:**
- Skipping Stage 1 and jumping straight to hypotheses.
- Generating hypotheses from the symptom alone without examining runtime behavior.
- Writing verification methods like "review the code" or "trace through the logic" — Stage 1 already did that; Stage 2 requires runtime evidence.
- Declaring root cause from code inspection alone. Code inspection produces hypotheses, not verifications. Verification requires running the code under observation.
- Declaring root cause from "this looks suspicious" — suspicion is a hypothesis.
- Picking the most plausible-sounding hypothesis and marking it CONFIRMED without runtime evidence, just to proceed to a fix.

**Record findings during diagnosis.** Every non-obvious insight encountered during Stage 1 or Stage 2 must be recorded as a finding in the issue or progress document.

### 5c. Diagnostic Tools — choose by failure class

Picking the right tool is part of the investigation, not an afterthought. Match the failure to the tool:

| Failure class | Primary tool | What to capture |
|---------------|--------------|-----------------|
| Crash / panic / segfault | lldb/gdb backtrace, core dump | full stack trace, local variable values at frame 0 |
| Wrong output / wrong behavior | instrumentation + reproduction | print/log values at each decision point leading to the wrong output |
| Silent failure / no-op | tracing (strace/dtrace), structured logging | which syscalls/log lines fire, which expected ones don't |
| Performance / hang | profiler (perf, Instruments, py-spy), tracing | hot stack samples, blocked threads, syscall wait times |
| Memory issues | valgrind/ASan/LeakSanitizer, `heap` in lldb | allocation sites, leak reports, use-after-free addresses |
| Concurrency / race | ThreadSanitizer, deterministic replay | conflicting accesses, happens-before relationships |
| Integration / external API | network trace (tcpdump/Charles), mock reproduction | request/response pairs, API version mismatches |
| Build / compile | full compiler error with `-Werror` flags, minimal reproduction | exact error + preprocessed source when macros involved |

Supporting tools (always available):
- `Grep` for locating code; `Read` for inspecting code; `git log -p` / `git blame` for history
- Dependency source reading (read the actual library source, not only docs)
- Web search for known issues / API behavior (cite URL in Investigation Log)

**Reading code is not debugging.** Reading tells you what the code *should* do. Debugging tools tell you what it *actually did* at runtime. Root cause verification requires the latter.

### 5d. Fix Process (follows RULE 3 + RULE 4)

After root cause is confirmed:
1. Formulate a fix plan (record in the issue document, or append a fix phase to the plan).
2. Review the fix plan for correctness and completeness.
3. Implement the fix.
4. **Code review the fix** — apply the C.3b Code Review checklist (logic, edge cases, error handling, performance, production quality, workarounds, style) to the modified files. Produce a `### Code Review: ISS-NNN (round M)` table in the issue document.
5. **Iterate** — if any column shows a concern or FAIL, fix and re-review. Code review is **unlimited rounds**: every code change triggers a fresh review, and reviews continue until the table has zero concerns and zero FAIL items.
6. Functional acceptance: build passes + fix verified + regression check (no new issues introduced).

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

This rule is triggered automatically after META-PHASE D step 6. It is NOT optional — do not stop or ask the user what to do next. Execute this rule immediately.

**Step 1: Assess current state.** Scan all documents in `docs/`:
- Issues with status `IN-PROGRESS` or `BLOCKED` in `docs/issue/`
- Findings marked `[UNVERIFIED]` across all documents
- Phases in other plan files that are still PENDING
- Dependencies that have been unblocked by the just-completed work

**Step 2: Determine if there is a next task.** If any of the following exist, there IS a next task:
- Unresolved issues (IN-PROGRESS or BLOCKED)
- Unverified findings
- Pending phases in active plans
- Known work items from the user's original task description

If none of the above exist, report completion to the user and stop.

**Step 3: Prioritize.** Rank candidates by:
- Blocking severity: tasks that unblock other work take precedence
- Impact scope: issues affecting multiple components over isolated ones
- Urgency: BLOCKED issues that now have a viable path forward
- Verification debt: accumulated [UNVERIFIED] findings

**Step 4: Plan and execute.** Create a new plan document for the selected task (following META-PHASE A → B flow) and continue execution (RULE 2). Do not pause between the completed plan and the new plan.

---

## Execution Summary

```
1. Bootstrap: run init-docs.sh
2. META-PHASE A: create plan with phases and expected results
3. META-PHASE B: review and refine plan (direct edits allowed)
4. META-PHASE C: for each phase:
   a. Pre-Phase: re-read plan, restate expected results
   b. Execute (record findings as they occur)
   c. Review: expected-vs-actual table → FAIL/PARTIAL items recorded as issues
   d. Fix issues → re-review (iterate until all PASS)
   e. Functional acceptance (RULE 4)
   f. Mark complete (only with review + acceptance artifacts)
5. META-PHASE D: final review, mark plan COMPLETED
6. RULE 7: assess state → plan next task → continue (mandatory, do not stop)
```

Begin now.
