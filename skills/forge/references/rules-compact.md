[/forge workflow rules — periodic refresh]

MANDATORY BANNER: Every response while forge is active MUST start with:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[/forge] plan=<name> · phase=<N>/<total> · meta=<A|B|C.1-C.5|C.3-fix|D|RULE5|RULE7> · issues=<open> · findings=<count>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Field values must come from actual file reads (ls docs/plan/, grep '### F-' docs, grep IN-PROGRESS docs/issue/), NOT from memory or estimation. Fabricated numbers = violation. Use `?` ONLY when data physically does not exist (e.g., empty docs/plan/ during META-PHASE A); never for issues/findings (use 0). Missing banner = drift detected = user will re-invoke /forge.

0. PRODUCTION QUALITY: Do NOT default to "simplest correct." Choose performant data structures/algorithms (not naive O(n²)), handle edge cases and failure modes, write production-ready code. Simplicity is not an excuse for poor performance or missing error handling.

1. SELF-MONITORING: Re-read the active plan file before each phase. If unsure about rules, re-read SKILL.md at ${CLAUDE_PLUGIN_ROOT}/skills/forge/SKILL.md.

2. CONTINUOUS EXECUTION: Do not pause, do not ask "shall I continue?", do not explain next steps — execute them. Only stop if user interrupts (ESC/Ctrl+C) or explicitly requests pause.

3. PHASED DEVELOPMENT: Follow META-PHASE A→B→C→D→RULE 7. CRITICAL:
   - Plan Review (META-PHASE B): MULTI-ROUND — write "### Plan Review" TABLE in progress (one row per phase: dependencies traced, expected results testable, feasibility with evidence, risks listed, stub/real marked). Each cell needs specific evidence, not "yes/fine/none". Draw dependency graph. FAIL/RISK → fix plan → re-review "### Plan Review (round M)". Repeat until all PASS.
   - Phase Review C.3 has TWO PARTS — both required:
     * C.3a Outcome: "### Review: Phase N — Outcome" — expected-vs-actual table.
     * C.3b Code: TWO STAGES. Stage 1 Investigation FIRST ("### Review: Phase N — Code · Investigation") — run git diff, Read each file, Grep anti-patterns (unwrap/todo/panic), Grep error paths, locate loops for complexity, run tests. Record exact tool outputs. Stage 2 Report ("### Review: Phase N — Code") — fill table with Logic/Edge Cases/Error Handling/Performance/Production Quality/Workarounds/Style. EVERY CELL MUST reference the investigation: "[investigation: <file> · <action>] observation". Cells without [investigation: ...] mean investigation was skipped = FAIL.
   - UNLIMITED ROUNDS: any FAIL or CONCERN in either review → record as issue → fix → re-review "(round M)". Repeat until BOTH reviews show zero FAIL and zero CONCERN. Every code change triggers a fresh review.
   - A phase CANNOT be marked COMPLETE without BOTH C.3a + C.3b clean + functional acceptance.
   - Bug fix process (RULE 5d) ALSO requires code review on the fix — apply same C.3b checklist, iterate until clean.
   Plan corrections during execution are append-only (mark old as [DEPRECATED], create new, cross-reference).

4. FUNCTIONAL ACCEPTANCE: After each phase — compile/build, compare results against plan expectations. PASS → continue. FAIL → record issue, fix, re-review.

5. DEBUGGING DISCIPLINE: No workarounds. STRUCTURED DIAGNOSIS — every issue requires a Diagnosis table with min 2 hypotheses, each with concrete verification method (exact command/log/code path) and verification result. Root cause requires CONFIRMED status from a verified hypothesis. Suspicion is NOT verification. Fix process follows principles 3+4 (plan fix → review → execute → verify + regression). Escalation: 3 failed fixes → change strategy; 5 failed plans → full re-evaluation; N similar issues → check broader scope systemically.

6. DOCUMENTATION + FINDINGS: Update docs/progress/ and docs/issue/ continuously. Formal technical language only. All claims require verifiable sources. Mark unverified content [UNVERIFIED]. Use /git-commit for commits. ACTIVELY RECORD FINDINGS during implementation and debugging. Empty Findings sections are a sign of skipped recording. Phase review must note findings count.

7. AUTONOMOUS PLANNING (MANDATORY after META-PHASE D): Do NOT stop after completing a plan. Scan docs/ for unresolved issues, [UNVERIFIED] findings, pending phases. If any exist → create new plan → continue. Only stop if nothing remains.
