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

## Token & Context Efficiency

/forge workflows are long-running and token-intensive. Token cost is a real budget — wasteful patterns compound across rounds of review and iteration. Efficient token usage is a quality attribute alongside performance and reliability.

**Rules:**

1. **Search before reading.** Use `Grep` and `Glob` to locate code before `Read`-ing files in full. Reading entire multi-thousand-line files to find one function is waste.
2. **Read diffs, not full files, during review rounds.** When re-reviewing after a fix (round M+1), read only the diff since the last round, not the full file again.
3. **Cite existing content; do not re-quote it.** In progress/issue docs, reference `[plan/<name>#PhaseN]` or `[F-NNN]` rather than copy-pasting the cited content.
4. **Do not re-enumerate the same state every response.** The banner provides state snapshot. Don't re-summarize plan status, open issues, and progress in prose if it's already in the banner and docs.
5. **Compact investigation outputs.** Investigation Logs record exact outputs that prove actions were taken — but truncate verbose output where the truncated portion is not load-bearing (e.g., include the relevant lines of a test output, not all 200 lines).
6. **Avoid redundant file reads within a phase.** If a file was read in C.1 Pre-Phase and has not changed, do not re-read in C.2/C.3 unless a specific reason exists.
7. **Delegate exploration to subagents for large codebases.** Subagents run in isolated contexts — they can read widely without polluting the main conversation. Use `Agent` with the `Explore` subagent type for broad searches.
8. **Prefer structured tool output over narrative.** A table or JSON summary Claude produces uses fewer tokens than a paragraph of prose. The banner, review tables, and diagnosis tables already follow this.

**Cost visibility:**

- At any point, the user can run `/usage` in Claude Code to see current session token consumption.
- At META-PHASE D.7 (Retrospective), the user is asked to paste the `/usage` output into the retrospective for that plan, enabling cost-per-plan tracking over time.
- If a single plan consumes disproportionate tokens (e.g., >2× the typical plan for similar scope), the retrospective must identify which phases or review rounds were expensive and what process improvement would reduce it next time.

**Warning signs of wasteful patterns:**

- Re-reading the same file across multiple review rounds without a specific reason (diff-only reviews suffice).
- Writing long narrative explanations of changes that duplicate what the diff already shows.
- Many INCONCLUSIVE diagnosis rounds — each costs tokens; if stuck at 2+ iterations, prefer BLOCKED + user consultation over more speculative verification attempts.
- Subagent calls with overly broad prompts causing the subagent to read huge swaths of the codebase when a targeted query would suffice.

**Not waste:** SKILL.md itself is long, but it loads once when /forge is invoked and is then replaced by periodic `rules-compact.md` injections (via the L1 hook every 10 tool calls). The canonical SKILL.md stays authoritative and detailed; the compact version handles in-flight refresh. Re-reading SKILL.md is only needed when rules feel unclear.

## Anti-Guessing — Evidence or Marker

The default failure mode of LLM-driven engineering is **substituting training-data plausibility for actual investigation**. When a question arises about how a codebase works, what an API does, or whether an approach is feasible, the path of least resistance is to produce a confident-sounding answer based on general knowledge. This is the single largest source of incorrect plans, broken implementations, and false debugging conclusions.

This rule defines the boundary: every technical claim must either be **grounded** (cite evidence in line) or **marked** (tagged `[GUESS]` until verified).

### What counts as a "technical claim"

Any statement asserting a fact about technical reality, including:
- "Function `foo` does X" / "Module `bar` exposes Y"
- "This library supports Z" / "This API returns W"
- "On macOS this syscall behaves differently"
- "This dependency has a method called K"
- "The codebase already has a similar feature in module M"
- "This approach is faster / more idiomatic / standard practice"
- "X version is compatible with Y version"

Statements about your own intentions, structure of the plan, or workflow steps are **not** technical claims and do not need this treatment.

### Grounding rules

A grounded technical claim cites evidence inline using one of these forms:

- File reference: `[src/auth/session.rs:L42-67]` (exact file + lines that prove the claim)
- Command output: `` [verified: `cargo tree -p foo`] `` (command run, output observed)
- Documentation reference: `[docs.rs/foo/0.5.2/foo/struct.Bar.html#method.baz]` (with URL and what the doc says)
- Cross-reference to prior verification: `[A3 CONFIRMED]` or `[F-NNN]` (pointing to existing evidence in the plan/findings)
- POC reference: `[POC: /tmp/poc.rs, output: ...]`

Without one of these, the claim is a **guess** — even if it is correct.

### Marker rules

When you are about to make a technical claim and have not (yet) gathered evidence, you have two options:

**Option A: Verify first.** Run the necessary tool call (Read/Grep/Bash) to gather evidence, then state the claim with the citation. This is preferred.

**Option B: Mark the claim and verify before acting.** Tag the claim with `[GUESS]` inline:

> "The function probably uses a mutex internally [GUESS] — to verify: read `src/cache.rs:Cache::get`."

A `[GUESS]`-tagged claim is provisional. It cannot be relied upon for:
- Plan structure (no `[GUESS]` claims as the basis for phase decomposition)
- Code design decisions (no `[GUESS]` claims as the basis for chosen approaches)
- Bug diagnosis (no `[GUESS]` claims as confirmed root causes)
- Acceptance verdicts (no `[GUESS]` claims as PASS evidence)

Before any of the above, every `[GUESS]` must be resolved into either a grounded claim (evidence cited) or rejected. The verification action stated in the marker is a contract — execute it, then update the claim.

### Where guesses commonly hide

These are the situations where guessing is most tempting and most damaging:

1. **"How does this codebase work?"** — When asked about an unfamiliar codebase, default to `Read`/`Grep` for the relevant module before describing it. Do not infer from naming or directory structure alone.
2. **"How does this library behave?"** — Library documentation can be wrong, outdated, or absent. The actual behavior is in the source. Read the dependency source for any non-trivial integration. Mark `[GUESS]` until you have either run it or read its implementation.
3. **"What's the standard way to do X?"** — There is rarely one standard way. Different ecosystems and codebases differ. Search this codebase first (Prior Art Survey, see A.2) for how X is done here, before invoking general patterns.
4. **"This should work on platform Y."** — Cross-platform claims must be verified per platform. `man <syscall>` on the actual target, `cargo tree --target=<triple>`, or POC compiled for target.
5. **"This will be fast / scalable."** — Performance claims require benchmarks, not reasoning from data structure choice alone. Mark `[GUESS]` until measured.
6. **"The bug is probably in X."** — Diagnosis hypotheses (RULE 5b H1, H2...) are explicitly guesses until runtime verification confirms. Never write a CONFIRMED status without runtime evidence.

### Enforcement

- C.3b Code Review subagent must scan the implementation for un-grounded claims in comments or commit messages and flag them as Workarounds-column issues.
- META-PHASE B Plan Review must reject any phase whose Expected Results, Risks, or Feasibility cite a claim without grounding (Feasibility cell already requires `[A#]` per existing rule; this extends to all cells).
- Any progress log or finding statement that asserts a technical fact without grounding is a violation. The PostToolUse hook can be extended to scan for un-grounded claims (future improvement).

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
- `meta` = exactly one of: `A.0` (requirements), `A.1` (analysis), `A.2` (ADR), `A.3` (feasibility), `A.4` (phase defs), `A.5` (test plan), `A.6` (write plan), `A.7` (write progress), `B` (plan-review), `C.1` (pre-phase), `C.2` (execute), `C.3a` (outcome review), `C.3b` (code review), `C.3-fix` (iterating fixes), `C.4` (acceptance), `C.5` (post-phase), `D.1` through `D.8` (completion sub-steps — use exact step), `RULE5` (debugging), `RULE7` (autonomous planning).
- `issues` = count of issues with status `IN-PROGRESS` or `BLOCKED` across all files in `docs/issue/`.
- `findings` = total count of `### F-NNN:` headers across all files in `docs/`.

### How to obtain field values

Field values **must be obtained from actual file reads** — not from memory or estimation — but need not be re-read on every response. Use this caching rule:

**Read on state transition; reuse within stable state.**

Refresh banner values by re-running the commands below when:
- Entering a new meta-phase (A.N → A.N+1, B → C.1, C.5 → next phase's C.1, C.3 → C.3a, etc.)
- After any Write/Edit to `docs/plan/`, `docs/progress/`, or `docs/issue/` (the hook signals this as a state change)
- After marking a phase COMPLETE or a plan COMPLETED
- When resuming after a user interaction (pause, answered Open Question, acceptance response)

Within the same meta-phase with no state-changing writes, reuse the most recent values. This balances accuracy with token efficiency (per the Token & Context Efficiency rule about avoiding redundant reads).

The refresh commands:

```bash
# Get all values in one shot
ls docs/plan/ 2>/dev/null
grep -c '### F-' docs/**/*.md 2>/dev/null || echo 0
grep -rE '(IN-PROGRESS|BLOCKED)' docs/issue/ 2>/dev/null | wc -l
```

Inventing or estimating values without having done a read in the current state is a violation. A banner with fabricated numbers is worse than no banner — it gives a false signal of compliance.

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

**Harness level (automatic):** The `PreToolUse` hook (`pre-tool-use-guard.sh`) injects a compact rules summary into the conversation context every 10 tool calls, and emits warnings when documentation maintenance lags behind execution (see thresholds in the hook). The hook never blocks tool calls — blocking here would deadlock the workflow when the only fix is to update docs. The `Stop` hook (`stop-guard.sh`) does block Claude from self-stopping while a plan's Status is ACTIVE. Both hooks operate independently of Claude's memory.

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
- When committing code, invoke `/git-commit`.

**The only reasons execution may stop (complete list — no others permitted):**

1. **User interrupt**: the user presses ESC/Ctrl+C or uses another Claude Code interrupt operation. Handled by the harness.
2. **User pause request**: the user explicitly requests a pause via text (e.g., "暂停", "pause", "stop"). Before stopping: mark the current plan `Status: PAUSED` so the `Stop` hook allows the stop.
3. **Unsolvable issue (RULE 3 re-plan trigger)**: after exhausting the RULE 5e escalation protocol with no resolution.
4. **A.0 Open Questions (mandatory stop)**: requirements are ambiguous, scope is unclear, or critical information is missing. STOP and ask the user — do NOT guess intent, do NOT invent requirements. Resume A.1 only after user answers. See META-PHASE A.0 for trigger conditions.
5. **D.5 User Acceptance Gate (mandatory stop)**: after presenting the Acceptance Summary at D.4, STOP and wait for explicit user acceptance of each AC. Resume D.6 only after user replies with "accept" or rework instructions.
6. **RULE 5b Stop Condition**: if after 2 investigation iterations no root cause is CONFIRMED, mark the issue BLOCKED and report to the user. Do not fix without a verified root cause.

Reasons 4 and 5 are **mandatory stops** required by other rules, not interruptions. They are part of correct execution, not deviations from RULE 2.

---

## RULE 3: Phased Development

### Bootstrap

Before any planning, initialize the documentation structure:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/forge/scripts/init-docs.sh
```

After bootstrap, **the very first substantive step is A.0 — Requirements Analysis, not A.1 (task analysis)**. Do not jump to reading code or exploring the codebase before producing the Requirements section. If requirements are ambiguous, STOP at A.0 Open Questions and ask the user before proceeding. The flow is strictly A.0 → A.1 → A.2 → A.3 → A.4 → A.5 → A.6 → A.7 → B; skipping or reordering steps is a violation.

### META-PHASE A: Planning

**A.0 — Requirements Analysis (mandatory before technical work).**

Before any technical exploration, extract structured requirements from the task description. This separates **what the user wants** from **how we will build it**. Mixing these causes acceptance criteria to be written from the implementer's perspective rather than the user's, which loses the ability to verify delivery against original intent.

**Create the plan file.** Copy the template from `${CLAUDE_PLUGIN_ROOT}/skills/forge/templates/plan.md` to `docs/plan/<name>.md` (choose `<name>` as a concise descriptor of the task). Fill in the header fields (Created, Status=ACTIVE, Source). This file will be populated section-by-section through A.0 → A.5; A.6 only verifies completeness and finalizes.

Now fill the `## Requirements` section:

```
## Requirements

### User Stories / Intent
<!-- One or more statements in the form: "As <user>, I want <capability>, so that <benefit>."
     Or for technical tasks: "The system must <capability> because <reason>." -->

### Acceptance Criteria (business-level, testable)
<!-- Each criterion must be: testable, written from the user's perspective, and independent
     of implementation choices. Number them AC-1, AC-2, ... -->

| ID | Criterion | How to verify (at delivery time) |
|----|-----------|---------------------------------|
| AC-1 | [user-observable behavior, e.g., "User can log in with email + password and receive a session token"] | [how an outsider would verify: "POST /login with valid credentials returns 200 + token cookie"] |
| AC-2 | ... | ... |

### Non-Functional Requirements (NFR)
<!-- Constraints that apply across all behavior. Include only what applies: -->
- **Performance**: [e.g., "login latency p99 < 300ms under 1000 rps"]
- **Security**: [e.g., "passwords never logged; tokens rotate on each login"]
- **Compatibility**: [e.g., "API must remain backward-compatible with v1 clients"]
- **Reliability**: [e.g., "login endpoint availability 99.9%"]
- **Compliance**: [e.g., "GDPR: user data deletion on request within 24h"]

### Open Questions for the User
<!-- Anything ambiguous, missing, or interpretable in multiple ways MUST be listed here. -->
```

Rules:
- **AC must be business-level, not implementation-level.** "The login function returns a Result" is implementation; "The user receives a session token after valid credentials" is business-level.
- **AC must be testable by an outside party.** If the only way to verify is to read the source code, the AC is not well-formed.
- **AC-N identifiers persist throughout the plan.** Phase expected results and tests will cross-reference them.

**Stop-and-ask rule (mandatory):** If any part of the task is ambiguous, interpretable in multiple ways, or has missing information, **STOP and ask the user** before proceeding. Do NOT guess user intent. Do NOT invent requirements to fill gaps. Do NOT pick the "most likely" interpretation silently.

Specifically, stop and ask when:
- The task description uses vague terms (e.g., "make it faster", "improve UX") without measurable criteria — ask for concrete targets.
- Multiple valid implementations satisfy the task differently — ask which matters more (e.g., speed vs accuracy, simplicity vs extensibility).
- Scope boundary is unclear (e.g., "add authentication" — for which endpoints? which users? which auth methods?).
- NFRs are not stated but likely matter (e.g., user-facing feature with no perf/security mention) — ask.
- The task references entities or concepts not in the codebase — ask for their definition or location.

The stop-and-ask is an explicit exception to RULE 2 (continuous execution). Asking clarifying questions during A.0 is required behavior, not interruption.

When asking: list the Open Questions in the plan document and in your response to the user. Wait for answers. Only proceed to A.1 after all Open Questions have been resolved with user input. Update the Requirements section with the confirmed answers before moving on.

**A.1 — Task Analysis & Codebase Reconnaissance (must produce an artifact).**

Reading code is not enough — produce a **Codebase Reconnaissance Log** in the plan document under `## Codebase Reconnaissance` to prove the reading happened and to capture what was learned. Without this artifact, A.1 was skipped.

The log records concrete actions taken to understand the codebase:

```
## Codebase Reconnaissance

### Search actions
| # | Action | Tool / Command | Outcome |
|---|--------|----------------|---------|
| S1 | Locate existing auth code | `Grep "fn login\|struct Session" src/` | found src/auth/session.rs (L1-180), src/auth/login.rs (L1-92) |
| S2 | Identify error type convention | `Grep "type Result" src/` | project uses Result<T, AuthError> in src/error.rs:L8 |
| S3 | Test conventions | `Read tests/auth/`, `Glob tests/**/*.rs` | tests use `#[tokio::test]` with `mock_db()` fixture |
| S4 | Module ownership | `Read docs/knowledge/ownership.md` | auth module: <responsible note>; depends on db, crypto |

### Files read (with what each contributed)
- `src/auth/session.rs:L1-180` — current Session struct, token expiry mechanism
- `src/auth/login.rs:L1-92` — entry point, currently uses bcrypt
- `src/error.rs:L1-50` — AuthError variants
- `Cargo.toml` — current crypto deps: bcrypt 0.15, ring 0.17

### Existing patterns identified (reusable)
- **Pattern 1**: All auth-related errors flow through AuthError enum at src/error.rs
- **Pattern 2**: Async functions use `#[tracing::instrument]` for observability (sample at src/auth/session.rs:L42)
- **Pattern 3**: Tests instantiate via `tests/common::mock_db()` rather than direct DB connection

### Similar features already in the codebase (use as reference)
- API key validation at src/auth/api_key.rs — same shape as planned session validation, can mirror the structure

### Constraints discovered
- C-1: Cannot break the v1 API contract per AC-3 (NFR compatibility)
- C-2: Existing sessions in production DB use SHA-256 hashed tokens — migration path required if changing
```

Rules:
- **Every entry must reference a real tool call.** `Grep`, `Read`, `Glob`, `Bash` outputs are evidence; assertions like "the auth module probably handles this" are not.
- **The log captures what is, not what could be.** Speculation about future implementation does not belong here — that's A.4. A.1 is descriptive of the current state.
- **Identify reusable patterns and similar features.** The most common waste in implementation is reinventing what the codebase already has. The "Similar features" subsection forces this discovery.
- **Identify constraints up front.** Anything in the codebase that limits the approach (versioning, conventions, existing schema) should be surfaced now, not discovered mid-execution.
- **A.1 directly informs A.2.** Alternatives considered in A.2 should reference reconnaissance findings ("Approach 1 follows the pattern already used at src/auth/api_key.rs").

If the recon turns up findings worth preserving as DISCOVERY findings (per RULE 6 Findings Mechanism), record them in `## Findings` of the plan document with `Type: DISCOVERY` and `Tags: layer:<area>`.

**A.2 — Approach identification & Architecture Decision Record (ADR).**

Before listing alternatives, conduct a **Prior Art Survey** — research existing solutions in this codebase, in the dependencies, and in the broader ecosystem. Pulling alternatives from training memory alone produces a list of plausible-sounding generic options that may not match this codebase's reality or the current state of practice.

###### Stage 0 — Prior Art Survey (mandatory before listing alternatives)

Produce a `### Prior Art Survey` subsection inside `## Architecture Decision`:

```
### Prior Art Survey

| # | Source | Search action | Findings |
|---|--------|--------------|----------|
| P1 | This codebase | `Grep "fn validate_token\|TokenValidator" src/` | api_key.rs uses HMAC; no JWT yet |
| P2 | Direct dependency | `Read deps/jwt-rs/src/lib.rs` (or `cargo doc`) | jwt-rs supports RS256 + HS256 only |
| P3 | Comparable projects | WebSearch "rust session token rotation crates" | tower-sessions (popular, async), session_cookie (sync), axum-login (framework-tied) |
| P4 | Authoritative docs | `WebFetch <RFC-7519-URL>` | JWT spec defines `exp`, `iat`, `nbf` claims |
| P5 | Known anti-patterns | WebSearch "JWT pitfalls auth common mistakes" | algorithm confusion, exp not enforced, key rotation issues |
```

Source categories (use those that apply, skip ones that don't):

- **This codebase** — search for similar features, reusable patterns (often discovered in A.1 reconnaissance; reference rather than re-discovering).
- **Direct dependencies** — if your approach builds on an existing library, read its source/docs to know what's actually available.
- **Comparable projects / crates / packages** — what do mature implementations of similar functionality look like? Use `WebSearch` for "<task> <language> crates" or "popular <task> libraries".
- **Authoritative specifications** — RFC, W3C spec, language standard, vendor docs. Fetch with `WebFetch` and cite the relevant section.
- **Known pitfalls / anti-patterns** — search "<task> common mistakes" or "<task> security issues". Surfaces failure modes others have hit.

Rules:
- Each row needs a real `Grep`/`Read`/`WebSearch`/`WebFetch` action. Pulling "I recall that pattern X exists" is a `[GUESS]` violation per Anti-Guessing rule.
- The Survey may eliminate alternatives before they are listed (e.g., "P3 confirmed tower-sessions handles all cases AC-1, AC-2 — reinventing is not justified") or surface alternatives you wouldn't have considered.
- For non-trivial design tasks (new system component, new external integration, novel algorithm), Prior Art Survey is mandatory. For trivial tasks (small bugfix, isolated refactor), document explicitly: `Prior Art Survey: N/A — task scope is local refactor of <module>; no external pattern applies`.

###### Stage 1 — Approach identification (informed by survey)

Now identify alternative approaches. Each alternative must reference Prior Art findings (which P# inspired it or which P# rules it out). For each, document technical pros, cons, and rationale. Tentatively select the approach with the strongest technical justification, pending feasibility verification in A.3.

The A.2 output is a formal **Architecture Decision Record (ADR)**, not just a comparison table. Produce an `## Architecture Decision` section in the plan document with this structure:

```
## Architecture Decision

**ADR ID**: ADR-NNN (sequential across the codebase; check existing ADRs in docs/ before choosing)
**Title**: <concise decision statement, e.g., "Use kqueue for event multiplexing on macOS instead of cros_async">
**Status**: PROPOSED (until A.3 feasibility passes; then becomes ACCEPTED)
**Date**: YYYY-MM-DD
**Context**: <What problem is being solved? What constraints apply? Link to AC-N and NFRs.>

### Alternatives Considered

| # | Approach | Pros | Cons | Verdict | Rationale |
|---|----------|------|------|---------|-----------|
| 1 | <chosen approach> | ... | ... | SELECTED | <why this one, in one sentence> |
| 2 | <alternative> | ... | ... | REJECTED | <specific reason with evidence> |
| 3 | <alternative> | ... | ... | REJECTED | <specific reason with evidence> |

### Decision

**Chosen approach**: <approach #1 name>

**Why**: <the technical argument — 2-4 sentences, not a narrative>

**Key assumptions** (to be verified in A.3): list the technical assumptions this decision rests on. These become A1, A2, ... in Feasibility Research.

### Consequences

- **Positive**: <what this decision enables or simplifies>
- **Negative**: <what this decision costs, risks, or makes harder>
- **Neutral / notable**: <other implications worth recording>

### Supersedes

<Optional. If this ADR replaces an earlier one: "Supersedes ADR-MMM because <reason>". The old ADR's status becomes SUPERSEDED.>
```

Rules for ADRs:
- **ADR ID is codebase-wide and sequential.** Before writing, check existing `docs/plan/*.md` and `docs/progress/*.md` for the highest ADR-N and use N+1.
- **Status lifecycle**: PROPOSED (during A.2) → ACCEPTED (after A.3 feasibility all CONFIRMED) → SUPERSEDED (if a later ADR replaces it) or DEPRECATED (if the decision is abandoned without replacement).
- **Alternatives are mandatory.** An ADR with only the chosen option is not a decision record — it's a declaration. Minimum 2 alternatives (including the chosen one).
- **Rejected alternatives must have evidence-based rationale.** "Not idiomatic" or "more complex" is insufficient without explaining what specifically is worse.
- **Link to ADR from phase definitions.** Any phase whose implementation depends on this architectural choice should reference `[ADR-NNN]` in its description.
- **Promote to permanent ADR in D.7.** At retrospective time, ADRs judged worth keeping long-term are collected into a codebase-wide ADR index (see D.7 and Finding Mechanism).

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
- **AC coverage**: which Acceptance Criteria (AC-N from A.0) this phase contributes to. A phase must contribute to at least one AC; if it does not, question whether it is necessary.
- Expected results: must be **precise and testable** — define what "implemented" means (compiles? passes tests? handles edge cases?). Distinguish between stub/placeholder and real implementation.
- Dependencies on prior phases: **build a dependency graph** and verify no circular dependencies exist.
- Risks and unknowns: for each phase, list what could go wrong and how to detect it early. Each risk should cross-reference the Feasibility Research assumption it relates to, or note "no A# — risk discovered here".

**A.5 — Test Plan (produced by an independent QA subagent).**

Designing tests after implementation creates a "self-grading" problem. Even designing tests before implementation has a subtler bias: the same assistant who will implement the code will naturally design tests that align with the implementation approach they have in mind, missing cases outside that mental model.

To break this bias, **A.5 must be delegated to a QA subagent** with scoped inputs:

- **Provide the subagent with**: the Requirements section (A.0 — AC + NFR) and the Phase objectives/expected results (A.4, headings only, NOT the implementation approach from A.2/A.3).
- **Do NOT provide the subagent with**: the Architecture Decision (A.2), the Feasibility Research POCs (A.3), or any hints about how the code will be structured.
- **Prompt**: "You are an independent QA engineer. Design a test plan from the provided Acceptance Criteria and NFRs. Do not assume any specific implementation. For every AC and NFR, derive unit / integration / E2E test cases. Every test case must trace to at least one AC-N or NFR. Negative tests are mandatory. Include edge cases derived from the requirements' value domains, not from code."

The subagent returns the Test Plan table. The main assistant writes it verbatim as the Test Plan subsection — no edits. If the main assistant disagrees with a test case, that disagreement is itself a signal (either the AC is unclear and must be clarified with the user, or the test caught an implementation shortcut).

For each phase, produce a **Test Plan** subsection in the plan document:

```
### Phase N: Test Plan

**Traces to AC**: AC-1, AC-3 (this phase contributes to these acceptance criteria)

| ID | Level | Test Case | Input / Setup | Expected Output / Behavior | Traces to AC |
|----|-------|-----------|---------------|---------------------------|--------------|
| T1 | unit | [specific function-level test] | [concrete input] | [concrete expected output] | AC-1 |
| T2 | integration | [cross-module test] | [setup + invocation] | [observable outcome] | AC-1, AC-3 |
| T3 | e2e | [end-to-end user scenario] | [user action sequence] | [user-observable result] | AC-3 |
| T4 | unit | [edge case: empty input] | [] | [specific handling] | AC-1 |
| T5 | unit | [edge case: max size] | [N=10^6] | [< 1s, no OOM] | AC-1 + NFR perf |
| T6 | integration | [failure mode: DB unavailable] | [DB down] | [graceful degradation per NFR] | NFR reliability |
```

Rules:
- **Test cases come from AC and NFR, not from the code.** If you are looking at the code to write tests, you are grading your own work.
- **Required coverage levels**:
  - **Unit**: every non-trivial function; every edge case identified in Phase expected results; every NFR that can be exercised at unit level (e.g., input validation).
  - **Integration**: every module boundary touched by the phase; every external dependency interaction; every failure mode (dependency down, timeout, partial response).
  - **E2E**: at least one happy path per AC; representative failure scenarios.
- **Each test case traces to at least one AC or NFR.** Tests that don't trace to anything are suspect — either the AC is missing or the test is unnecessary.
- **Negative tests are mandatory.** For every expected behavior, identify at least one failure input/state and how the system must handle it.
- **If a level does not apply** (e.g., pure library with no integration points): state explicitly `Level=integration: N/A because <reason>`. Silence is not acceptable.

**A.6 — Finalize the plan.** The plan document at `docs/plan/<name>.md` has been built up incrementally during A.0–A.5 (A.0 creates the file by copying the template at `${CLAUDE_PLUGIN_ROOT}/skills/forge/templates/plan.md`, each subsequent step fills in its section). At A.6, verify the file contains all required sections — **Requirements** (A.0), **Codebase Reconnaissance** (A.1), **Architecture Decision** including **Prior Art Survey** and **ADR-NNN** (A.2), **Feasibility Research** (A.3), **Phases with expected results, AC coverage, dependencies, risks, related ADRs** (A.4), **Test Plan per phase** (A.5) — and set `Status: ACTIVE`. Any missing section means the corresponding A.N step was skipped — go back and complete it.

**A.7 — Create the corresponding `docs/progress/<name>.md`** using the progress template. Log the planning action to the progress document.

### META-PHASE B: Plan Review

Re-read the entire plan document. Produce a **Plan Review** entry in the progress document under `### Plan Review`. This is a structured, multi-round review — not a formality.

**The review MUST use this exact table format** (one row per phase):

```
### Plan Review

| Phase | Dependencies OK | Expected Results Testable | Feasibility | Risks Identified | Stub/Real Marked | AC Coverage | Test Plan Adequate | Verdict |
|-------|----------------|--------------------------|-------------|-----------------|-----------------|-------------|--------------------|---------|
| 1     | [trace: no deps] | [how to verify each result] | [cite A#] | [list risks w/ A# refs] | [which are stubs] | [AC-N traced] | [levels + neg tests] | PASS/FAIL/RISK |
| 2     | [Phase 1 outputs X, Phase 2 needs X → OK / CIRCULAR] | ... | ... | ... | ... | ... | ... | ... |
```

Each cell must contain **specific evidence**, not assertions. Examples of what is NOT acceptable vs acceptable:

| Column | NOT acceptable | Acceptable |
|--------|---------------|------------|
| Dependencies OK | "yes" | "Phase 2 needs compiled libfoo.a from Phase 1 output → verified Phase 1 produces it" |
| Expected Results Testable | "yes, can test" | "Verify via: `cargo test --lib hvf` must pass 3 tests; `cargo build` exit 0" |
| Feasibility | "should be fine" or any text not referencing A# | "[A3 CONFIRMED] kqueue API available, `man kqueue` returned on macOS 14" or "[A7 CONFIRMED + POC] 30-line POC at /tmp/poc.rs exec success" |
| Risks | "none" | "Risk: cros_async has no macOS backend [A5 CONFIRMED via `cargo tree -p cros_async -f '{p} {f}'`]" |
| AC Coverage | "covers AC" | "AC-1 via expected results 1,2; AC-3 via expected result 4" |
| Test Plan Adequate | "yes" | "unit: 3 cases covering AC-1 happy/empty/max; integration: T4 covers AC-1 failure mode; e2e: T5 covers AC-3; negative tests present" |

**Feasibility column must reference the Feasibility Research assumptions (A1, A2, ...) from META-PHASE A.3.** A Feasibility cell that does not cite an A# means the feasibility was not actually verified — treat as FAIL.

**AC Coverage column**: each phase must list which AC-N it contributes to, traced to specific expected results. A phase with no AC contribution is suspect — either the phase is unnecessary or the AC is missing.

**Test Plan Adequate column**: verify that the Phase Test Plan (from A.5) has (1) unit/integration/E2E coverage as applicable, (2) negative tests for every expected behavior, (3) every test traces to AC or NFR, (4) NFR coverage for any NFR relevant to this phase. Missing any of these → FAIL.

**Additional cross-cutting checks** (separate section after the table):

1. **Dependency graph**: draw the actual dependency order. Verify no cycles. Format: `Phase 1 → Phase 2 → Phase 3; Phase 1 → Phase 4`. If a cycle exists, it must be resolved before proceeding.
2. **Alternatives completeness**: for each rejected alternative in the plan (from A.2 ADR), verify it has evidence-based rationale. Flag any that were dismissed without investigation.
3. **AC completeness**: every AC-N from A.0 must appear in at least one phase's AC Coverage. An AC not covered by any phase is a planning gap — fix before proceeding.
4. **NFR coverage**: every NFR from A.0 must have at least one phase's Test Plan that exercises it, OR an explicit deferral to META-PHASE D verification with rationale.

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

**Reviewer independence (mandatory):** C.3a and C.3b must be performed by a **subagent**, not by the main conversation. The main assistant implemented the phase; if the same context also reviews it, the review is biased toward self-justification. A subagent starts fresh, without the main conversation's reasoning, and evaluates the work as an outside reviewer would.

To run an independent review:
- Use the `Agent` tool to spawn a subagent with `subagent_type: "general-purpose"` (or `"code-reviewer"` if available).
- **Construct the prompt by replacing placeholders with concrete values** before calling the tool. The prompt templates in C.3a and C.3b contain placeholders in angle brackets: `<name>`, `N`, `<base-ref>`. Substitute them with the actual plan filename (without `.md`), the phase number, and the appropriate git ref (e.g., the commit SHA from the start of the phase, or `HEAD~K` where K is the commit count during the phase). Never pass a literal `<name>` or `N` to the subagent.
- Include in the prompt: the concrete plan document path (`docs/plan/<actual-name>.md`), the phase number, the AC IDs the phase traces to (from A.4 AC coverage), and the specific files modified during this phase (from `git diff --name-only`).
- The subagent reads the plan, the test plan, and the modified code independently. It has no knowledge of the implementer's internal reasoning.
- The subagent returns the review table(s) as its final output.
- The main assistant writes the subagent's output verbatim to the progress document as `### Review: Phase N — Outcome` and `### Review: Phase N — Code`.

The main assistant **does not edit the subagent's findings**. If the subagent found issues, record them as-is. Disagreements with the subagent's findings are themselves findings worth recording.

##### C.3a — Outcome Review (produced by subagent)

Prompt the subagent with:

"You are an independent QA reviewer. Do THREE things:

1. **Run the planned tests**: for each test in the Test Plan (A.5) for Phase N, execute it (use the appropriate test command for the project), capture the actual output, and record PASS/FAIL with evidence.

2. **Derive supplementary tests from AC/NFR**: independently read the Requirements section (A.0) and the Phase expected results. Identify any AC or NFR coverage that the planned tests may have missed (edge cases, failure modes, boundary values). Design 1–5 additional tests and run them. Record them in the review with `[supplementary]` marker.

3. **Produce the Outcome Review table**: one row per Expected Result of Phase N, mapping to PASS/FAIL/PARTIAL, evidence from both planned and supplementary tests, and any AC that the phase failed to deliver.

Do not read the implementation code for this review beyond what is necessary to run the tests. Your job is to verify from the outside."

Format:

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

##### C.3b — Code Review (produced by subagent)

A passing outcome review (C.3a) does NOT mean the code is acceptable. Code can satisfy expected results yet contain hidden bugs, edge case failures, performance problems, workarounds, or quality issues.

**C.3b must also be performed by a subagent** — the same independence requirement as C.3a. Prompt a fresh subagent with: "Read the plan at `docs/plan/<name>.md` for Phase N context, then review the code changes for this phase. First produce a C.3b Investigation Log with the required investigation actions below, then produce a Code Review table. Do not trust any claims from the implementer — verify everything by reading the actual code and running the specified tool calls."

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

#### Approach Abandonment Gate (must precede any switch of approach)

When implementation hits friction and the impulse is to switch to a different approach: **STOP**. The default response to friction is "investigate this specific failure" (per RULE 5b), not "abandon the approach."

A claim of "this approach doesn't work" is itself a technical claim and must be grounded (per RULE 0c Anti-Guessing). Without grounding, it is a `[GUESS]` — and switching approaches based on a guess compounds the problem: the new approach may hit the same actual root cause, undiagnosed.

**Two distinct failure modes this gate prevents:**

- **Mode A (premature optimism)** — declaring "this approach will work" without evidence. Addressed by A.3 Feasibility Research + RULE 0c Anti-Guessing.
- **Mode B (premature pessimism)** — declaring "this approach won't work" without evidence. Addressed by THIS gate.

Both are cases of a confident-sounding judgment substituting for actual investigation.

##### Pre-conditions for abandoning an approach (all required)

1. **Full RULE 5b investigation cycle completed** for the failure that prompted reconsideration. At least one Stage 1 (runtime investigation) → Stage 2 (verified hypothesis) cycle has run. The root cause is **CONFIRMED** with runtime evidence — not INCONCLUSIVE, not "this looks like the approach is wrong."

2. **Root cause classified as approach-level, not detail-level**:
   - **APPROACH-LEVEL**: the root cause invalidates an A# Feasibility Research assumption, OR makes an AC unachievable under any implementation of the chosen approach.
   - **DETAIL-LEVEL**: a specific code, config, version, integration, or environment choice; a different implementation of the same approach could resolve it.

3. **Detail-level fixes attempted before abandonment**: if there is any plausible detail-level cause, attempt at least one fix per RULE 5d. Per RULE 5e, "no fixable variant within the approach" requires 3 different failed fix attempts (genuinely different fixes, not the same fix retried).

##### Mandatory artifact: Approach Abandonment Decision

Before declaring an approach infeasible, produce a `### Approach Abandonment Decision` entry in the progress document:

```
### Approach Abandonment Decision

**Trigger**: [what symptom prompted reconsideration of the approach]

**RULE 5b investigation reference**: [issue/<name>.md#ISS-NNN — link to Diagnosis section with verified root cause]

**Confirmed root cause**: [statement, with concrete evidence: file path, command output, debugger trace, profiler output]

**Classification**: APPROACH-LEVEL

**Evidence the issue is approach-level (not detail-level)**:

| Source | Evidence | Conclusion |
|--------|----------|------------|
| A# invalidation | [A3 was CONFIRMED via `man kqueue`; now invalidated because <new evidence>] | Assumption no longer holds |
| AC unachievability | [AC-2 (latency p99 < 300ms) requires <X>; the chosen approach has minimum <Y> due to <evidence>] | AC cannot be met under this approach |
| Variants tried | V1: <approach + result>; V2: <variant + result>; V3: <variant + result> — all hit <same constraint> at <evidence> | No implementation of this approach satisfies <AC/NFR> |

**Decision**: ABANDON

**Next step**: mark current plan `Status: DEPRECATED`, return to META-PHASE A with this evidence as input. The new plan must address the invalidated assumption directly.
```

If the evidence does not meet the bar — the root cause is INCONCLUSIVE, only one variant tried, or the failure is plausibly detail-level — the decision must be **CONTINUE WITH FIX**: return to RULE 5d. Do not abandon.

##### Anti-patterns explicitly forbidden

- **"This is more complex than I thought, switching to simpler approach"** — complexity is not infeasibility. Complexity is a separate concern (Overriding Principle: production-grade quality, not simplest correct).
- **"First fix didn't work, the approach must be wrong"** — single failure ≠ approach failure. RULE 5e requires 3+ failed fixes before changing strategy.
- **"I have a better idea now, let me switch"** — record the better idea as a candidate ADR for the next plan, but finish investigating the current failure first. Without finishing investigation, you cannot tell if the "better idea" is actually better or just different.
- **"The error message hints the approach is wrong"** — error messages often mislead. Verify with runtime evidence before drawing structural conclusions.
- **"The library doesn't do exactly what I expected"** — read its source. Sometimes there's a workaround at the integration layer (detail-level), sometimes there's a real limitation (approach-level). The difference is verifiable.
- **"The fix is taking too long, switching is faster"** — sunk-cost reasoning. Switching to an undiagnosed alternative likely takes longer overall because the new approach may hit the same root cause or a different one with no learning carried forward.

##### Cost of skipping this gate

- The new approach may hit the same actual root cause (e.g., a dependency limitation that affects all approaches), still undiagnosed.
- Genuine fixable bugs get hidden behind an "abandoned" plan and never resolved.
- Multiple plans get abandoned for what was actually one detail-level issue, exhausting effort.
- Sunk-cost spirals: each switch leaves implementation work that won't be reused.
- Knowledge loss: the plan's findings, ADR, and feasibility evidence become orphaned without the lessons learned being preserved as findings.

#### Re-Plan Trigger
A re-plan (returning to META-PHASE A) is triggered by exactly two paths:

1. **RULE 5e exhaustion** — 5 different failed plans for the same issue (per the escalation protocol).
2. **Approach Abandonment Gate passed** — the Abandonment Decision artifact above shows APPROACH-LEVEL root cause with sufficient evidence.

When triggered:
1. Mark the current plan `Status: DEPRECATED`, add `Superseded-by: [plan/<new-name>]`.
2. Create a new plan file referencing the deprecated plan and explaining what changed and why.
3. Restart from META-PHASE A with accumulated findings (especially the verified root cause from the abandonment investigation — this becomes a CONSTRAINT or DISCOVERY finding informing the new plan's A.0/A.2/A.3).

### META-PHASE D: Completion

**D.1 — Full review.** Perform these checks and record findings in progress under `### META-PHASE D Review`:

1. **Plan completeness**: every phase in the plan has Status=COMPLETE. If any is still PENDING/ACTIVE, go back to C and finish it.
2. **All review + acceptance artifacts present**: each phase has `### Review: Phase N — Outcome`, `### Review: Phase N — Code`, and `### Functional Acceptance: Phase N` with PASS verdicts.
3. **AC coverage audit**: every AC-N from A.0 Requirements is addressed by at least one completed phase. Any orphan AC → record as a gap.
4. **NFR verification audit**: every NFR from A.0 was either tested at phase level (per Test Plan) or has an explicit deferred verification plan for D.
5. **Knowledge artifact audit**:
   - `docs/knowledge/api/` current for all public APIs touched in this plan? Missing/stale → record as issue.
   - `docs/knowledge/onboarding/architecture.md` reflects architecture changes made by this plan?
   - `docs/knowledge/ownership.md` reflects module changes (added/moved/renamed/removed)?
   - Any operational procedure introduced by this plan needs a runbook in `docs/knowledge/runbooks/`?
6. **Tribal knowledge test**: for each non-trivial decision, quirk, or workaround in the current plan, is it captured as a finding (DECISION/WARNING/DISCOVERY) AND promoted to the relevant knowledge artifact where structural?
7. **Session-continuity test**: could a fresh Claude session resume work on this project using only `docs/` content? If not, record what is missing.
8. **Open issues**: all `IN-PROGRESS` issues from this plan's execution are either resolved (`RESOLVED`) or explicitly deferred (`NOT-NEEDED` or `BLOCKED` with a gap finding).

Any issue discovered here must be addressed before D.4 (Acceptance Summary) — either fix in place, or explicitly record as a GAP finding with a plan to resolve later.

**D.2** — Run final compilation/build verification.

**D.3** — Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/forge/scripts/check-doc-format.sh` to validate documentation.

**D.4 — Acceptance Summary (mandatory, user-facing).**

Before marking the plan COMPLETED, produce an **Acceptance Summary** as a direct response to the user. This is the user's opportunity to verify delivery against the original requirements, from the outside.

The summary must contain:

1. **AC traceability table** — one row per Acceptance Criterion from A.0:

   ```
   | AC ID | Criterion (from A.0) | Delivered state | Evidence (how user can verify) |
   |-------|---------------------|-----------------|--------------------------------|
   | AC-1  | [original criterion text] | [what was built that addresses it] | [command / URL / file / test output user can check] |
   | AC-2  | ... | ... | ... |
   ```

2. **NFR verification** — one line per non-functional requirement from A.0, stating how it was validated (or marked `[UNVERIFIED]` with reason).

3. **Known gaps / deferred work** — any AC/NFR partially met or deferred, each cross-referenced to the issue or finding tracking it.

4. **Outstanding issues** — summary of any open `IN-PROGRESS` or `BLOCKED` issues.

**D.5 — User Acceptance Gate (blocking).**

After presenting the Acceptance Summary, **stop and ask the user for explicit acceptance**. This is the second explicit exception to RULE 2 (continuous execution), and it is required.

Ask: "Please confirm whether each AC is accepted. Reply with 'accept' to mark the plan COMPLETED, or list specific AC-N that need rework."

Wait for the user's response. Do not proceed.

- If the user accepts: proceed to D.6.
- If the user rejects specific AC: return to the appropriate phase (or META-PHASE A if the requirement itself needs to change). The rejection and its reason are recorded in the plan document as a Plan Correction.
- If the user requests changes: treat as new requirements — return to A.0 if scope changes, or the appropriate phase if only implementation needs adjustment.

**D.6** — Only after user acceptance: mark the plan `Status: COMPLETED` and write a summary entry in progress.

**D.7 — Retrospective (mandatory).**

Before proceeding to RULE 7, produce a **Retrospective** entry in the progress document under `### Retrospective`:

```
### Retrospective

**What went well**: [3-5 concrete items, e.g., "Feasibility POC for kqueue caught the platform issue early"]

**What did not go well**: [concrete items — plan corrections forced, unexpected blockers, skipped rules, rework rounds > 3]

**Root causes**: [for each item in "did not go well", what upstream decision or missing check caused it?]

**Process improvements for next plan**: [concrete changes to how future plans are constructed — new assumptions to always check, templates to add, etc.]

**DECISION findings promoted to ADR**: [list F-NNN entries (Type=DECISION) that meet ADR significance criteria — affect multiple modules, set codebase-wide patterns, will be referenced by future plans — and were promoted to new ADR-NNN entries. For each, note: F-NNN → ADR-NNN.]

**Token & cost review**:

Ask the user to run `/usage` in Claude Code and paste the output here. Then analyze:

| Item | Value |
|------|-------|
| Total tokens this plan | [from /usage] |
| Approximate cost | [if shown] |
| Tokens per completed phase | total / number of phases |
| Most expensive phase(s) | [by tool-call count if known, or observed review round count] |
| Rework multiplier | [number of review/diagnosis rounds across all phases — target ≤ 1.5 per phase] |

**Cost-efficiency observations**: [what activities consumed disproportionate tokens? e.g., repeated full-file reads, many INCONCLUSIVE diagnosis rounds, bloated investigation logs. Tie each observation to a process improvement.]

**Budget for next plan of similar scope**: [estimate based on this plan's actual usage, adjusted by planned improvements]
```

**D.8** — Proceed to RULE 7 (autonomous task planning) — do NOT stop here.

---

## RULE 4: Functional Acceptance

After each phase implementation (META-PHASE C.4), execute the full acceptance procedure. All steps are mandatory — a phase cannot pass acceptance on build alone.

### 4.1 Build verification
- Compile, build, lint, or type-check as appropriate for the project.
- Record the exact command and its output in the progress document.
- A failing build is an immediate FAIL — do not proceed to 4.2.

### 4.2 Execute the Test Plan (all three levels)

Run every test defined in the phase's A.5 Test Plan. Record each by ID (T1, T2, ...) with exact command and output.

| Level | Requirement | Evidence format |
|-------|-------------|-----------------|
| Unit | All unit tests in the Test Plan PASS | test runner output per test ID |
| Integration | All integration tests in the Test Plan PASS | test runner output or integration harness logs per test ID |
| E2E | All E2E tests in the Test Plan PASS | end-to-end script output or manual verification trace per test ID |

Format in progress document under `### Functional Acceptance: Phase N`:

```
### Functional Acceptance: Phase N

**Build**: [command] → [exit code + summary]

**Test execution**:

| Test ID | Level | Command | Result | Output excerpt |
|---------|-------|---------|--------|----------------|
| T1 | unit | cargo test --lib foo::bar | PASS | test foo::bar ... ok |
| T2 | integration | ... | PASS | ... |
| T3 | e2e | ... | PASS | ... |

**Coverage check**: every AC-N in the phase's AC coverage has at least one corresponding test that passed.

**Overall**: PASS / FAIL
```

### 4.3 Regression check
- Run the full existing test suite (not just the new tests for this phase) to verify no prior functionality was broken.
- Record: total tests run, passed, failed, and any newly-failing tests with their exact output.

### 4.4 NFR verification
- For each NFR from A.0 that applies to this phase, run the relevant verification (perf benchmark, security scan, compatibility check, etc.).
- If an NFR is not testable at phase level, explicitly record `NFR-<name>: deferred to META-PHASE D verification` with rationale.

### 4.5 Result
- **PASS** (all of 4.1–4.4 clean): log to progress with evidence, continue to C.5.
- **FAIL** (any step failed): record the deviation in `docs/issue/<name>.md` with status `IN-PROGRESS`, reference the failing test ID(s), enter RULE 5 (debugging). After fix, return to C.3 (re-review) before retrying C.4.

A test that was planned in A.5 but not executed during C.4 is a violation — the Test Plan is the acceptance contract.

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

### Findings Mechanism (Knowledge Management)

Findings are durable knowledge. A bare title + one-liner is **not** a finding — it is a note that will be unusable in six months. Every finding must be structured so that a future engineer (or future Claude session) can read it out of context and understand: what was discovered, why it matters, what evidence backs it, and what to do with it.

###### Finding Types

Every finding must be classified as exactly one of these types:

- **DECISION** — an architecture/design decision made (equivalent to an ADR). Includes rationale, considered alternatives, and consequences.
- **DISCOVERY** — a non-obvious technical fact learned about the system, a dependency, or the environment. Not a decision; a piece of reality we now know.
- **CONSTRAINT** — a limitation or requirement imposed by external reality (platform, dependency, legal, business) that affects future work.
- **WARNING** — a known pitfall or gotcha that future work should avoid. Often derived from a bug that was fixed; the lesson is preserved even if the bug is closed.
- **BENCHMARK** — a quantitative measurement of performance, resource usage, or capacity. Serves as a baseline for future regression detection.
- **GAP** — a known unaddressed issue or deferred work that is too small or out-of-scope to be a full issue entry. Tracks "we know this is imperfect."

###### Finding Structure (mandatory)

Every finding uses this exact structure:

```
### F-NNN: <concise title>

**Type**: DECISION | DISCOVERY | CONSTRAINT | WARNING | BENCHMARK | GAP
**Status**: ACTIVE | SUPERSEDED | OBSOLETE | [UNVERIFIED]
**Date**: YYYY-MM-DD
**Tags**: <space-separated tags for search, e.g., `platform:macos performance rust hvf`>
**Context**: <which phase, which issue, which investigation produced this finding>

**Statement**:
<One paragraph stating the finding precisely. For DECISION, state the decision itself. For DISCOVERY, state the fact. For CONSTRAINT, state the limit. For WARNING, state the pitfall. For BENCHMARK, state the measurement. For GAP, state the unaddressed problem.>

**Evidence**:
<Concrete source backing the finding. File paths with line numbers, command outputs, URLs, POC file references. No assertions without evidence.>

**Impact / So what**:
<Who or what is affected by this finding. What code paths, what future work, what decisions does it constrain or inform? A finding without stated impact is just trivia.>

**Related**:
<Optional. Cross-references to other findings, issues, phases: [F-NNN], [issue/core#ISS-003], [plan/auth#Phase2]. Supersedes/Superseded-by for DECISION evolution.>
```

###### Type-specific additional fields

**DECISION** (acts as an ADR):
- **Alternatives considered**: brief list with why each was rejected
- **Consequences**: positive and negative effects of the decision

**WARNING**:
- **Trigger**: the specific condition that causes the problem
- **Mitigation**: how to avoid or handle it

**BENCHMARK**:
- **Environment**: hardware, OS, config snapshot where measured
- **Method**: exact command or workload used

**GAP**:
- **Resolution path**: what would it take to close this gap? When should it be revisited?

###### Finding Status Lifecycle

- **ACTIVE** — finding is current and valid.
- **[UNVERIFIED]** — the finding was recorded but the evidence is provisional. Must include `Verification plan:` describing how to verify. Cannot be cited as authoritative.
- **SUPERSEDED** — a later finding replaces this one (decision changed, discovery refined). Must include `Superseded-by: [F-MMM]`.
- **OBSOLETE** — the subject of the finding no longer exists (code removed, dependency dropped). Keep for historical trace; do not cite.

Do not delete findings. Update status instead.

###### Tag Conventions

Tags enable finding search across the docs/ tree. Use consistent tag namespaces:

- `platform:<os>` — platform-specific (e.g., `platform:macos`, `platform:linux`)
- `layer:<layer>` — architectural layer (e.g., `layer:vm`, `layer:net`, `layer:ui`)
- `dep:<name>` — related dependency (e.g., `dep:cros_async`)
- `perf`, `security`, `correctness`, `usability` — cross-cutting concerns
- `api:<component>` — API-related
- `arch` — architecture-level

Tags are lowercase, hyphenated, space-separated.

###### Internal and Cross-Document Reference

- Internal reference: `[F-NNN]`.
- Cross-document reference: `[plan/<name>#F-NNN]`, `[progress/<name>#F-NNN]`, `[issue/<name>#F-NNN]`.

###### ADR vs DECISION finding — how they relate

There are two decision records in this system, serving different purposes:

- **ADR (A.2 output)**: one **primary architectural decision** per plan — the top-level approach choice that shapes the entire implementation. Formally tracked with ADR-NNN, PROPOSED→ACCEPTED lifecycle, and placed in the plan's `## Architecture Decision` section. One plan typically has exactly one ADR.

- **DECISION finding** (F-NNN Type=DECISION): **smaller design decisions made during implementation** — choices about data structures, API shapes, module boundaries, naming conventions, error handling strategies, etc. These accumulate throughout C.2 Execute as trade-offs arise. One plan can produce many DECISION findings.

Use ADR for: "We chose kqueue over cros_async for event multiplexing." (one big choice at plan start)

Use DECISION finding for: "In `auth::session`, we chose a BTreeMap over HashMap to preserve iteration order for audit logging." (local choice discovered during implementation)

###### Promoting DECISION findings to plan-level ADRs

Occasionally a DECISION finding made during implementation turns out to be architecturally significant — it affects more than its local scope. At META-PHASE D.7 Retrospective, review all DECISION findings. For each:

- If it meets **ADR significance criteria** (affects multiple modules, sets a codebase-wide pattern, will be referenced by future plans, constrains future design): promote it by creating a new ADR-NNN entry in the plan document that references the finding. List the promotion in the Retrospective under "Findings promoted to ADR."
- If it remains local in scope: keep as a DECISION finding; do not promote.

Promoted ADRs join the codebase's ADR history alongside the plan's primary ADR (from A.2).

###### Findings are not optional

Empty Findings sections signal that Claude skipped recording. Every non-trivial phase produces at least 1 finding; every non-trivial issue produces at least 1 finding (usually a WARNING preserving the lesson learned from the bug).

If a phase's Findings section has zero entries, you must either:
1. Record findings from the phase that were missed (most common case), or
2. Note in the phase review: `**Findings rationale**: no non-obvious discoveries in this phase because <specific reason>`. "Nothing interesting happened" is not sufficient — explain why the phase had no architectural/behavioral discoveries.

### Project-Level Knowledge Artifacts

Findings capture granular discoveries. But a project also needs **structural, durable knowledge** that outlives individual plans and helps future contributors (including future Claude sessions) get productive quickly. These artifacts live at `docs/knowledge/` and are maintained across plans.

###### 1. User-facing / API documentation

Distinct from internal progress docs. These describe **how to use the system**, not how it was built.

Location and structure:
- `docs/knowledge/api/` — public API reference: endpoints, function signatures, parameters, return types, error codes, examples
- `docs/knowledge/user-guide.md` — end-user or caller-facing usage guide (when applicable)

Rules:
- **Any phase that adds, changes, or removes a public API must update `docs/knowledge/api/` in the same phase.** This is part of Expected Results — if an API changes and the doc doesn't, the phase is incomplete.
- **Every public function/endpoint/type documented has**: signature, purpose (one sentence), parameters (with constraints), return value, error conditions, minimal example.
- **Breaking changes**: highlighted at the top of the relevant doc section with migration instructions.
- C.3b Code Review must verify the API doc is current; missing/stale doc → FAIL.

###### 2. Onboarding documentation

For a new contributor (or new Claude session) to understand the codebase fast.

Location: `docs/knowledge/onboarding/`
- `README.md` — 5-minute orientation: what this project does, how to build/run, where to find things
- `architecture.md` — system architecture at a level someone can mentally model in 15 minutes: major components, data flow, trust boundaries, external dependencies
- `conventions.md` — code style, naming, module boundaries, test patterns, git workflow specific to this repo
- `development-setup.md` — tooling, environment, common commands, troubleshooting

Update rules:
- **Created on first plan's META-PHASE D if missing.** If `docs/knowledge/onboarding/README.md` does not exist at D.1 of the first plan, create it as part of D.
- **Updated whenever architecture changes.** Any phase that adds a major component, changes data flow, or alters trust boundaries must update `architecture.md` in the same phase.
- **Audited at every META-PHASE D.1** (full review step): read the onboarding docs and confirm they match current reality. Stale onboarding doc → issue recorded.

###### 3. Code / Module Ownership Matrix

Maps modules to their purpose, dependencies, and responsible area. Enables quick impact analysis and prevents accidental cross-cutting changes.

Location: `docs/knowledge/ownership.md`

Format:

```
# Module Ownership Matrix

| Module | Path | Purpose (1 sentence) | Public API | Depends on | Used by | Related ADRs | Notes |
|--------|------|---------------------|------------|------------|---------|--------------|-------|
| auth | src/auth/ | Session token issuance and validation | `login()`, `validate_token()` | db, crypto | api, admin | ADR-012 | Security-sensitive; see F-023 |
| ... | | | | | | | |
```

Update rules:
- **New module created** → must be added to the matrix in the same phase.
- **Module renamed / moved / deleted** → matrix updated in the same phase.
- **Dependency added between modules** → both rows updated.
- **Audited at every META-PHASE D.1**: does the matrix reflect the actual module layout? Mismatch → issue recorded.

###### 4. Runbooks (operational knowledge)

For any system component that can fail in production or requires manual intervention.

Location: `docs/knowledge/runbooks/`
- One file per failure mode or operation: `deploy.md`, `rollback.md`, `db-migration.md`, `cert-rotation.md`, etc.

Each runbook contains:
- **Trigger**: when to use this runbook
- **Pre-check**: how to confirm the trigger applies
- **Steps**: numbered, copy-pasteable commands
- **Post-check**: how to confirm the operation succeeded
- **Rollback**: how to undo if the operation fails mid-way
- **Escalation**: who/what to notify if the runbook does not resolve the situation

Created when: a phase introduces a production-affecting capability, a new operational procedure, or resolves an incident that might recur.

###### 5. Bus Factor / Knowledge Backup

"Bus factor" = the number of people (or in our case, sessions) who can be lost before the project is stuck. The artifacts above collectively reduce bus factor, but this must be actively maintained:

- **Tribal knowledge test** at META-PHASE D.1: for each non-trivial decision, quirk, or workaround in the current plan, is it captured in a DECISION/WARNING/DISCOVERY finding AND (if structural) promoted to the relevant knowledge artifact (ADR index, ownership matrix, runbook)?
- **Untestable assumption**: if the only way someone would know a fact about the system is to have been in the current conversation, it is tribal knowledge and must be externalized before the session ends.
- **Session-continuity test**: before META-PHASE D.5 (user acceptance gate), ask: "If this conversation disappeared right now and a fresh Claude session picked up the project, could it resume work effectively using only `docs/` content?" If not, what is missing? Record and fix.

###### Knowledge artifact audit in META-PHASE D

META-PHASE D.1 (full review) must explicitly audit these artifacts:
- API docs current for all public APIs touched in this plan? (If not → issue)
- Onboarding docs still accurate? (Architecture changes reflected?)
- Ownership matrix reflects the current module layout?
- Any operational procedures introduced that need runbooks?
- Any tribal knowledge in the conversation that was not externalized?

Gaps found here are addressed before D.5 user acceptance.

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

This rule is triggered automatically after META-PHASE D.8. It is NOT optional — do not stop or ask the user what to do next. Execute this rule immediately.

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
0. Bootstrap: run init-docs.sh (creates docs/{plan,progress,issue,knowledge}/ and .forge-counter)

META-PHASE A — Planning:
  A.0 Requirements (User Stories, AC-N, NFR, Open Questions)
      → if ambiguous: STOP + ask user (RULE 2 exception)
  A.1 Task analysis
  A.2 ADR-NNN (formal Architecture Decision Record, PROPOSED)
  A.3 Feasibility Research (A1, A2, ... all CONFIRMED → ADR ACCEPTED)
  A.4 Phase definitions (each traces to AC, with deps/risks)
  A.5 Test Plan per phase (via independent QA subagent; unit/integration/E2E)
  A.6 Write plan.md
  A.7 Create progress.md

META-PHASE B — Plan Review:
  Table covering dependencies / expected results / feasibility (cite A#) / risks
  / stub-real / AC coverage / test plan adequacy. Multi-round until all PASS.
  Plan document may be edited directly during B.

META-PHASE C — Phase Execution (loop per phase):
  C.1 Pre-Phase: re-read plan, restate expected results
  C.2 Execute (record findings as they occur)
  C.3 Review (by independent subagent, multi-round until clean):
      C.3a Outcome (run Test Plan + derive supplementary tests)
      C.3b Code (Investigation Log → Report Table with [investigation:] refs)
      Any FAIL/CONCERN → record issue → fix → re-review
  C.4 Functional Acceptance (RULE 4): build + unit/integration/E2E + regression + NFR
  C.5 Post-Phase: mark COMPLETE (pre-condition: all review+acceptance artifacts)
  (on bug: RULE 5 — investigation → verified root cause → fix → code review)

META-PHASE D — Completion:
  D.1 Full review + knowledge artifact audit (api/onboarding/ownership/runbooks)
  D.2 Final build verification
  D.3 Run check-doc-format.sh
  D.4 Acceptance Summary (AC traceability table, NFR verification, gaps)
  D.5 User Acceptance Gate — STOP + wait for user accept (RULE 2 exception)
  D.6 Mark Status: COMPLETED
  D.7 Retrospective (What went well/didn't/root causes/improvements/cost review)
  D.8 → RULE 7

RULE 7 — Autonomous Planning (mandatory, not optional):
  Scan docs/ for open issues, [UNVERIFIED] findings, pending phases, GAPs.
  If anything remains: create new plan, return to META-PHASE A.
  If nothing remains: report completion to user and stop.
```

Begin now.
