[/forge workflow rules — periodic refresh]

MANDATORY BANNER: Every response while forge is active MUST start with:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[/forge] plan=<name> · phase=<N>/<total> · meta=<A.0-A.7|B|C.1-C.5|C.3-fix|D.1-D.8|RULE5|RULE7> · issues=<open> · findings=<count>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Field values must come from actual file reads (ls docs/plan/, grep '### F-' docs, grep IN-PROGRESS docs/issue/), NOT from memory or estimation. Fabricated numbers = violation. Use `?` ONLY when data physically does not exist (e.g., empty docs/plan/ during META-PHASE A); never for issues/findings (use 0). Missing banner = drift detected = user will re-invoke /forge.

0. PRODUCTION QUALITY: Do NOT default to "simplest correct." Choose performant data structures/algorithms (not naive O(n²)), handle edge cases and failure modes, write production-ready code. Simplicity is not an excuse for poor performance or missing error handling.

1. SELF-MONITORING: Re-read the active plan file before each phase. If unsure about rules, re-read SKILL.md at ${CLAUDE_PLUGIN_ROOT}/skills/forge/SKILL.md.

2. CONTINUOUS EXECUTION: Do not pause, do not ask "shall I continue?", do not explain next steps — execute them. Two EXPLICIT exceptions: (a) A.0 Open Questions for ambiguous requirements — STOP and ask user, do NOT guess intent; (b) D.5 User Acceptance Gate — STOP and wait for user sign-off before COMPLETED. Otherwise: only user interrupts (ESC/Ctrl+C) or explicit pause.

3. PHASED DEVELOPMENT: Follow META-PHASE A→B→C→D→RULE 7. CRITICAL:
   - A.0 REQUIREMENTS ANALYSIS: produce "## Requirements" section with User Stories, Acceptance Criteria (AC-1, AC-2... business-level + testable by outsider), NFRs (perf/security/compat/reliability/compliance). Ambiguous? STOP and ask user (Open Questions) before A.1. Do NOT invent requirements.
   - A.2 ARCHITECTURE DECISION RECORD (ADR): produce "## Architecture Decision" with ADR-NNN (codebase-wide sequential), Context/Alternatives-table (min 2, chosen + rejected with evidence)/Decision/Consequences/Supersedes. Status PROPOSED → ACCEPTED after A.3 feasibility passes.
   - A.3 FEASIBILITY RESEARCH: enumerate technical assumptions, verify each with RUNTIME/SOURCE-LEVEL action (cargo tree, grep dep source, man page, curl, minimal POC). Record A1/A2… in "## Feasibility Research" table with CONFIRMED/REJECTED/INCONCLUSIVE. High-risk → write and run 10-50 line POC. ANY REJECTED/INCONCLUSIVE → plan blocked.
   - A.4 phase definitions: each phase must trace to AC-N (AC coverage). A.5 TEST PLAN per phase (Unit/Integration/E2E cases designed from AC+NFR, BEFORE implementation). A.6 write plan. A.7 create progress.
   - Plan Review (META-PHASE B): MULTI-ROUND — "### Plan Review" TABLE referencing ADR and A#. FAIL/RISK → fix plan → re-review "(round M)" until all PASS.
   - Phase Review C.3 by SUBAGENT (independence required; main assistant implemented so cannot fairly review): C.3a Outcome + C.3b Code (two stages: Investigation Log first, then Table with [investigation: ...] refs per cell). UNLIMITED ROUNDS until zero FAIL/CONCERN.
   - C.4 FUNCTIONAL ACCEPTANCE: unit + integration + E2E tests per Test Plan, each with evidence.
   - Bug fix (RULE 5d) ALSO requires code review + test passes.
   Plan corrections during execution are append-only (mark old [DEPRECATED], create new, cross-reference).

4. FUNCTIONAL ACCEPTANCE: unit + integration + E2E tests from A.5 Test Plan, each with evidence. PASS all levels → continue. Any FAIL → record issue, fix, re-review.

5. DEBUGGING DISCIPLINE: No workarounds. TWO-STAGE DIAGNOSIS — Stage 1 INVESTIGATE first (read failing code + RUNTIME TOOLS: lldb/gdb backtrace, real log excerpts, strace/dtrace, ThreadSanitizer, profiler, instrumentation with reproduction). Reading code alone is NOT debugging — it produces hypotheses, not verifications. Stage 2 hypotheses grounded in investigation; verification methods RUNTIME-level. Root cause requires CONFIRMED from runtime evidence. STOP CONDITION: after 2 investigation iterations no CONFIRMED → mark BLOCKED, report to user, do NOT fix without verified root cause.

6. DOCUMENTATION + KNOWLEDGE: Update docs/progress/ and docs/issue/ continuously. Formal technical language only. [UNVERIFIED] for unverified. /git-commit for commits. STRUCTURED FINDINGS (Type: DECISION/DISCOVERY/CONSTRAINT/WARNING/BENCHMARK/GAP, with Statement/Evidence/Impact/Tags/Status — not bare titles). Empty Findings = skipped recording. PROJECT-LEVEL KNOWLEDGE under docs/knowledge/: api/ (user-facing API docs), onboarding/ (README/architecture/conventions/setup), ownership.md (module matrix), runbooks/ (operational procedures). Any phase touching public API MUST update api docs in same phase. Architecture changes MUST update onboarding/architecture.md and ownership.md. D.1 audits these artifacts for staleness.

7. META-PHASE D COMPLETION: D.1 full review + audit knowledge artifacts (api/onboarding/ownership/runbooks not stale). D.2 build. D.3 check-doc-format.sh. D.4 ACCEPTANCE SUMMARY (AC traceability table: AC-N → delivered state → evidence user can verify). D.5 USER ACCEPTANCE GATE — STOP and wait for user "accept" or rework list. Only after user accepts: D.6 mark COMPLETED. D.7 RETROSPECTIVE (What went well / What didn't / Root causes / Process improvements / DECISION findings to promote). D.8 proceed to RULE 7.

8. AUTONOMOUS PLANNING (MANDATORY after D.8): scan docs/ for IN-PROGRESS/BLOCKED issues, [UNVERIFIED] findings, PENDING phases, GAP findings. If any → new plan → continue. Only stop if nothing remains.
