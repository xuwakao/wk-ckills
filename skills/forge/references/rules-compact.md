[/forge workflow rules — periodic refresh]

0. PRODUCTION QUALITY: Do NOT default to "simplest correct." Choose performant data structures/algorithms (not naive O(n²)), handle edge cases and failure modes, write production-ready code. Simplicity is not an excuse for poor performance or missing error handling.

1. SELF-MONITORING: Re-read the active plan file before each phase. If unsure about rules, re-read SKILL.md at ${CLAUDE_PLUGIN_ROOT}/skills/forge/SKILL.md.

2. CONTINUOUS EXECUTION: Do not pause, do not ask "shall I continue?", do not explain next steps — execute them. Only stop if user interrupts (ESC/Ctrl+C) or explicitly requests pause.

3. PHASED DEVELOPMENT: Follow META-PHASE A→B→C→D→RULE 7. CRITICAL:
   - Plan Review (META-PHASE B): MULTI-ROUND — write "### Plan Review" TABLE in progress (one row per phase: dependencies traced, expected results testable, feasibility with evidence, risks listed, stub/real marked). Each cell needs specific evidence, not "yes/fine/none". Draw dependency graph. FAIL/RISK → fix plan → re-review "### Plan Review (round M)". Repeat until all PASS.
   - Phase Review (C.3): MULTI-ROUND — write "### Review: Phase N" with expected-vs-actual table. FAIL/PARTIAL items → record as issues in docs/issue/ → fix → re-review "### Review: Phase N (round M)". Repeat until ALL rows are PASS. Single-round review that ignores problems is a violation.
   - A phase CANNOT be marked COMPLETE without a PASS review + functional acceptance artifacts.
   Plan corrections during execution are append-only (mark old as [DEPRECATED], create new, cross-reference).

4. FUNCTIONAL ACCEPTANCE: After each phase — compile/build, compare results against plan expectations. PASS → continue. FAIL → record issue, fix, re-review.

5. DEBUGGING DISCIPLINE: No workarounds. STRUCTURED DIAGNOSIS — every issue requires a Diagnosis table with min 2 hypotheses, each with concrete verification method (exact command/log/code path) and verification result. Root cause requires CONFIRMED status from a verified hypothesis. Suspicion is NOT verification. Fix process follows principles 3+4 (plan fix → review → execute → verify + regression). Escalation: 3 failed fixes → change strategy; 5 failed plans → full re-evaluation; N similar issues → check broader scope systemically.

6. DOCUMENTATION + FINDINGS: Update docs/progress/ and docs/issue/ continuously. Formal technical language only. All claims require verifiable sources. Mark unverified content [UNVERIFIED]. Use /git-commit for commits. ACTIVELY RECORD FINDINGS during implementation and debugging. Empty Findings sections are a sign of skipped recording. Phase review must note findings count.

7. AUTONOMOUS PLANNING (MANDATORY after META-PHASE D): Do NOT stop after completing a plan. Scan docs/ for unresolved issues, [UNVERIFIED] findings, pending phases. If any exist → create new plan → continue. Only stop if nothing remains.
